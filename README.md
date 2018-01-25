<p align="center">
  <img width="25%" height="25%" src="https://www.blackducksoftware.com/sites/default/files/images/Logos/BD-S.png">
</p>

# Overview
AWS CodePipeline is a continuous delivery service you can use to model, visualize, and automate the steps required to release your software. Black Duck's integration with AWS Code Pipeline provides an easy way to automatically build any application using AWS CodeBuild and scan it for any open source vulnerabilities using Black Duck Hub Detect.

Note: Black Duck Hub Detect consolidates functionality of several Black Duck scanning tools, package managers, and continuous-integration plugin tools. Hub Detect makes it easier to set up and scan applications using a variety of languages and package managers.

AWS CodePipeline offers Custom Actions that can be leveraged to simplify the integration of Black Duck Software into AWS CodePipeline. This document describes how to configure an AWS CodePipeline Custom Action to initiate a Hub Detect scan after a build of either:

	* AWS CodeBuild projects, or 
	* non-CodeBuild projects built on a particular S3 bucket path

Note: The procedure described here achieves a result similar to the Black Duck CodeBuild integration procedures, but with simpler configuration.  By using AWS CodePipeline Custom Actions, you do not have to edit each CodeBuild project's source code (buildspec.yml) to initiate a scan.

# Documentation
https://blackducksoftware.atlassian.net/wiki/spaces/PARTNERS/pages/56360977/Black+Duck+AWS+CodePipeline

# Limitations
There are limitations as to what can be scanned by Black Duck Hub Detect when invoked by an AWS CodePipeline Custom Action. Generally, only the following can be scanned:

	* Fat JARs (JAR files containing all dependencies)
	* WAR or TAR files containing all dependencies
	* Docker Images in any Docker registry, including the Amazon EC2 Container Registry (ECR)

When invoked by an AWS CodePipeline Custom Action, Black Duck Hub Detect cannot, for example, scan a JAR file that contains source but no dependencies.

Also note that private Docker registries are not supported.


