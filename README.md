lambda-transcoder
=================

AWS lambda function to transcode AVI videos to MP4 on upload to S3.

This lambda function uses ffmpeg to transcode video files in response to AWS S3 PutObject events. Given the limited memory, storage and time available to a lambda function we assumes that the video snippets are very short. The particular use-case considered is to transcode video snippets generated from Raspberry Pi running motion from AVI to MP4 format so that they are natively viewable on a OS X or IOS device.

In order for the function to work correctly there are a number of prerequisites required. These include the async and fluent-ffmpeg node js modules as well as static ffmpeg binary compiled from source. All of this needs to be packaged up as a zip file so that it can be uploaded to the AWS Lambda service. The make-lambda-function.sh script has included to facilitate the creation of the transcoder.zip file ready for upload.

