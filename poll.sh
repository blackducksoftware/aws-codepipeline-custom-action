#!/bin/bash

set -eu

if [[ -z "${1:-}" ]]; then
  echo "Usage: ./poll.sh <action type id>" >&2
  echo -e "Example:\n  ./poll.sh \"category=Build,owner=Custom,version=1,provider=BlackDuck-HubDetect-Scan\"" >&2
  exit 1
fi

run() {
  local action_type_id="$1"

  while :
  do
    local job_json="$(fetch_job "$action_type_id")"

    echo "job json : $job_json" >&2

    if [[ "$job_json" != "null" && "$job_json" != "None" && "$job_json" != "" ]]; then
      create_build "$job_json"

      acknowledge_job "$job_json"

      wait_for_build_to_finish "$job_json"
    else
      sleep 3
    fi
  done
}

fetch_job() {
  local action_type_id="$1"

  echo "Waiting for CodePipeline job for action-type-id '$action_type_id'" >&2

  aws codepipeline poll-for-jobs --max-batch-size 10 \
                                 --action-type-id "$action_type_id" \
                                 --query 'jobs[0]'
}

action_configuration_value() {
  local job_json="$1"
  local configuration_key="$2"

  echo "$job_json" | jq -r ".data.actionConfiguration.configuration | .[\"$configuration_key\"]"
}

fail_job() {
  local job_json="$1"

  local job_id="$(echo "$job_json" | jq -r '.id')"

  echo "Error the CodePipeline job for job id '$job_id'" >&2

  aws codepipeline put-job-failure-result \
      --job-id "$job_id" \
      --failure-details "type=JobFailed,message=Build Failed,externalExecutionId=$job_id"
  
  cd ../; rm -rf $job_id

  sleep 3

  continue
}

create_build() {
  local job_json="$1"

  local project_name=$(action_configuration_value "$job_json" "Black Duck Hub Project Name")

  echo "Found job. Creating build for $project_name" >&2
}

acknowledge_job() {
  local job_json="$1"
  local project_name=$(action_configuration_value "$job_json" "Black Duck Hub Project Name")

  local job_id="$(echo "$job_json" | jq -r '.id')"
  local nonce="$(echo "$job_json" | jq -r '.nonce')"

  echo "Acknowledging CodePipeline job for $project_name (id: $job_id nonce: $nonce)" >&2

  aws codepipeline acknowledge-job --job-id "$job_id" --nonce "$nonce" > /dev/null 2>&1 || fail_job "$job_json"
}

update_job_status() {
  local job_json="$1"
  local output="$2"

  local job_id="$(echo "$job_json" | jq -r '.id')"
  local project_name=$(action_configuration_value "$job_json" "Black Duck Hub Project Name")

  echo "Updating CodePipeline job for $project_name with success/failure result" >&2

  if [[ "$output" -eq 0 ]]; then
    aws codepipeline put-job-success-result \
      --job-id "$job_id" \
      --execution-details "summary=Build succeeded,externalExecutionId=$job_id,percentComplete=100" || fail_job "$job_json"
  else
    aws codepipeline put-job-failure-result \
      --job-id "$job_id" \
      --failure-details "type=JobFailed,message=Build Failed,externalExecutionId=$job_id"
  fi
}

wait_for_build_to_finish() {
  local job_json="$1"
  local job_id="$(echo "$job_json" | jq -r '.id')"

  # Retrieve the custom action input parameters
  local blackduck_project_name=$(action_configuration_value "$job_json" "Black Duck Hub Project Name")
  local blackduck_project_version_name=$(action_configuration_value "$job_json" "Black Duck Hub Project Version Name")
  local bucket_name="$(echo "$job_json" | jq -r ".data.inputArtifacts[0].location.s3Location | .[\"bucketName\"]")"
  local object_key="$(echo "$job_json" | jq -r ".data.inputArtifacts[0].location.s3Location | .[\"objectKey\"]")"
  local s3_bucket_name=$(action_configuration_value "$job_json" "S3 Bucket Name")
  local ecr_region_name=$(action_configuration_value "$job_json" "ECR Region Name")
  local image_name=$(action_configuration_value "$job_json" "Image Name")

  # Retrieve hub Url and Credentials
  local hubUrl=$(aws ssm get-parameters --names BLACKDUCK_HUB_URL --query Parameters[0].Value)
  local hubUserName=$(aws ssm get-parameters --names BLACKDUCK_HUB_USERNAME --query Parameters[0].Value)
  local hubPassword=$(aws ssm get-parameters --names BLACKDUCK_HUB_PASSWORD --with-decryption --query Parameters[0].Value)

  # Retrieve docker Url and Credentials
  local dockerUrl=$(aws ssm get-parameters --names BLACKDUCK_DOCKER_URL --query Parameters[0].Value)
  local dockerUserName=$(aws ssm get-parameters --names BLACKDUCK_DOCKER_USERNAME --query Parameters[0].Value)
  local dockerPassword=$(aws ssm get-parameters --names BLACKDUCK_DOCKER_PASSWORD --with-decryption --query Parameters[0].Value)
  
  local scan_location=""

  # Get the scan location
  if [ -z "$object_key" ] || [ $object_key == 'null' ]; then
    scan_location="$(echo $s3_bucket_name)"
  else
    scan_location="$(echo $bucket_name/$object_key)"
  fi

  local hub_project_version=""

  # Get the Hub project version
  if [ -z "$blackduck_project_version_name" ]  || [ $blackduck_project_version_name == 'null' ]; then
    hub_project_version="$(echo $job_id)"
  else
    hub_project_version="$(echo $blackduck_project_version_name)"
  fi

  mkdir $job_id
  chmod +x $job_id
  # Download and execute Hub detect
  cd $job_id || fail_job "$job_json"; \
  aws s3 cp s3://$scan_location . || fail_job "$job_json"; \
  curl -LOk https://blackducksoftware.github.io/hub-detect/hub-detect.sh || fail_job "$job_json"; \
  if [ -z "$image_name" ]  || [ $image_name == 'null' ]; then \
    bash hub-detect.sh  --blackduck.hub.url=$hubUrl \
    --blackduck.hub.username=$hubUserName \
    --blackduck.hub.password=$hubPassword \
    --detect.project.name=$blackduck_project_name \
    --detect.project.version.name=$hub_project_version \
    --detect.risk.report.pdf=true || fail_job "$job_json"; \
  else \
    if [ -z "$ecr_region_name" ]  || [ $ecr_region_name == 'null' ]; then \
      docker login -u $dockerUserName -p $dockerPassword $dockerUrl; \
    else \
      aws ecr get-login --no-include-email --region $ecr_region_name | sh; \
    fi; \
    bash hub-detect.sh --detect.docker.image=$image_name --blackduck.hub.url=$hubUrl \
    --blackduck.hub.username=$hubUserName \
    --blackduck.hub.password=$hubPassword \
    --detect.project.name=$blackduck_project_name \
    --detect.project.version.name=$hub_project_version \
    --detect.risk.report.pdf=true || fail_job "$job_json"; \
  fi; \
  aws s3 cp *.pdf s3://$s3_bucket_name/ --sse aws:kms || fail_job "$job_json"; \
  cd ../ || fail_job "$job_json"; \
  rm -rf $job_id  || fail_job "$job_json"

  local output=$?
  echo "Build finished for $blackduck_project_name" >&2

  update_job_status "$job_json" "$output"
}

run "$1"
