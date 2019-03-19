<p align="center">
  <img width="25%" height="25%" src="https://www.synopsys.com/content/dam/synopsys/sig-assets/images/BlackDuck_by_Synospsy_onwhite.png">
</p>

## Overview
AWS CodePipeline is a continuous delivery service you can use to model, visualize, and automate the steps required to release your software. Black Duck's Custom Action for AWS CodePipeline allows automatic identification of Open Source Security, License, and Operational risks during your application build process.


## What is Black Duck?

[Black Duck by Synopsys](https://www.synopsys.com/software-integrity/security-testing/software-composition-analysis.html) helps organizations identify and manage open source security, license compliance and operational risks in their application portfolio. Black Duck is powered by the world’s largest open source KnowledgeBase™, which contains information from over 13,000 unique sources, includes support for over 80 programming languages, provides timely and enhanced vulnerability information, and is backed by a dedicated team of open source and security experts. The KnowledgeBase™, combined with the broadest support for platforms, languages and integrations, is why 2,000 organizations worldwide rely on Black Duck to secure and manage open source.

## How does the scan work?

The CodePipeline Custom Action runs Synopsys Detect against your application build as a Test action.

Synopsys Detect consolidates functionality of several Black Duck scanning tools, making it easy to scan applications using a variety of languages and package managers.

Black Duck's AWS CodePipeline Custom Action is able to run a Black Duck Detect scan against a build of either:

	* AWS CodeBuild projects, or 
	* non-CodeBuild projects built to a S3 bucket

Note: The procedure described here achieves a result similar to the Black Duck CodeBuild integration procedures, but with simpler configuration.  By using AWS CodePipeline Custom Actions, you do not have to edit each CodeBuild project's build spec (buildspec.yml) to initiate a scan.

## Limitations
There are limitations as to what can be scanned by Black Duck Detect when invoked by an AWS CodePipeline Custom Action. Generally, only the following can be scanned:

	* Fat JARs (JAR files containing all dependencies)
	* WAR or TAR files containing all dependencies
	* Docker Images in Public Docker Registries 
	* Docker Images in Amazon Container Registry (ECR)

When invoked as a Custom Action, Black Duck Detect cannot, for example, scan a JAR file that contains source but no dependencies.

## Documentation

Instructions and examples for the AWS CodePipeline Custom Action are available on our [Public Confluence](https://synopsys.atlassian.net/wiki/x/bgBy).

For information on the full capabilities of Detect visit [Synopsys Detect Docs](https://synopsys.atlassian.net/wiki/x/SYC4Aw).

## Pre-Requisites

Before calling Detect in as a Custom Action, an instance of Black Duck is required.

If you do not have Black Duck, refer to [Black Duck on AWS](https://synopsys.atlassian.net/wiki/spaces/PARTNERS/pages/7471220/Deploying+Black+Duck+AMI+on+AWS) for more information.

## Want to contribute?

Running into an issue? Please file an issue against our [Github repository](https://github.com/blackducksoftware/aws-codepipeline-custom-action).  


