lambda-transcoder
=================

This AWS lambda function uses ffmpeg to transcode short AVI videos to MP4 in response to AWS S3 PutObject events. Given the limited memory, storage and time available to a lambda function we assumes that the video snippets are very short. The particular use-case considered is transcoding video snippets generated from a Raspberry Pi running motion from AVI to MP4 format so that they are natively viewable on a OS X or IOS device.

In order for the function to work correctly there are a number of prerequisites required. These include the async and fluent-ffmpeg nodejs modules as well the ffmpeg binary compiled from source to include all dependencies. This is then packaged up as a zip file so that it can be uploaded to the AWS Lambda service. The make-lambda-function.sh script is included to facilitate the creation of the transcoder.zip file ready for upload.

It is recommended that you build the lambda function on an Amazon Linux machine to ensure that it is fully compatible. However I have built the lambda function on a CentOS v6.5 image and this runs fine.

The generated zip file can be uploaded via the AWS console. The following parameters are recommended to ensure that you provide maximum resources to the function - these can be trimmed once you are familiar with the time and memory footprint of your typical transcodes.

```
File name = transcode.js
Handle name = handler
Role = arn:aws:iam::<account_id>:role/<role_name>
Memory (MB) = 1024
Timeout (s) = 60
```

- two buckets should be created: \<bucket-name\> and \<bucket-name\>-transcoded
- a lambda execution IAM role should be created (with policy outlined below)
- a lambda invocation IAM role should be created 
- run upload-lambda-function.sh, specifying the ARN lambda execution role created above as an input parameter

The lambda execution IAM role should have a policy that looks something like this:

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::<bucket-name>/*"
    },
    {
      "Effect": "Allow",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::<bucket-name>-transcoded/*"
    }
  ]
}
```
The lambda invocation IAM role should have a policy that looks something like:

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Resource": [
        "arn:aws:lambda:<region>:<account-id>:function:<lambda-function-name"
      ]
    }
  ]
}
```

the following trust relationship: 

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringLike": {
          "sts:ExternalId": "arn:aws:s3:::*"
        }
      }
    }
  ]
}
```
