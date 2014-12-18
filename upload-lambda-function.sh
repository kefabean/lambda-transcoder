#!/bin/bash
if [ $# -ne 1  ]
  then
    echo "Usage: upload-lambda-function.sh <role-id>"
    exit
fi
cd transcoder
zip -r ../transcoder.zip *
cd ..
echo Uploading lambda function to execute with role: $1
aws lambda upload-function --function-name transcoder --function-zip transcoder.zip --timeout 60 --memory-size 1024 --runtime nodejs --role $1 --handler 'transcode.handler' --mode event

