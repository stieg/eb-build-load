# EB-Build-Load

A Werker step designed to create a zip archive of the code in
WERCKER_ROOT, upload it to S3 and then create a Amazon beanstalk
application version within an existing Beanstalk application.

This step assumes that your current code is already setup to be
used within the beanstalk environment and does not require any
major modifications.

You can provide an optional `.zipexclude` file that the step will
honor when creating the archive.  Be sure to read the zip manpage
for how to properly format this file.

## Requirements

This step requires the following applications to be already available:

* aws
* git
* zip

Please ensure whatever box you are using for your build has these applications
already installed and at a resonable version.

## Use
```
deploy:
  steps:
  - airfordable/eb-build-load:
      aws_access_key: $AWS_ACCESS_KEY
      aws_region: $AWS_REGION
      aws_secret_key: $AWS_SECRET_KEY
      eb_app_name: <enter app name>
      eb_version: [optional version label, else uses `git describe --always --dirty`]
      s3-bucket: <enter s3 bucket name>
```
