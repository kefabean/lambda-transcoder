process.env['PATH'] = process.env['PATH'] + ':' + process.env['LAMBDA_TASK_ROOT'];
console.log('Loading event');
var aws = require('aws-sdk');
var s3 = new aws.S3({apiVersion: '2006-03-01' });
var ffmpeg = require('fluent-ffmpeg');
var util = require('util');
var async = require('async');
var fs = require('fs');

exports.handler = function(event, context) {
	// Write event to console log
	console.log(JSON.stringify(event, null, '  '));

	// Get the object from the event and show its content type
	var srcBucket   = event.Records[0].s3.bucket.name;
	var srcKey      = event.Records[0].s3.object.key;
	var srcFileName = '/tmp/' + srcKey;
	var dstBucket   = srcBucket + "-transcoded";
	var dstKey      = srcKey + ".mp4";
	var dstFileName = '/tmp/' + dstKey;

	// Validate that source and destination are different buckets
	if (srcBucket == dstBucket) {
	  console.error("Destination bucket must not match source bucket.");
	  return;
	}
	// Infer the input format type
	var typeMatch = srcKey.match(/\.([^.]*)$/);
	if (!typeMatch) {
		console.error('unable to infer image type for key ' + srcKey);
		context.done(null,''); 
		return;
	}
	var imageType = typeMatch[1];
	if (imageType != "avi") {
		console.log('skipping non-image ' + srcKey);
		context.done(null,'');
		return;
	}

	async.waterfall( [
		function download(next) {
			// download the file from s3
			console.log("Downloading ", srcKey, " from S3");
			s3.getObject({ Bucket: srcBucket, Key: srcKey }, next);
		},
		function writetodisk(response, next) {
			// write the file to disk
			console.log("Writing file downloade from S3 to ", srcFileName);
			var tmpfile = fs.writeFile(srcFileName, response.Body, next);
		},
		function tranform(next) {
		 	// transcode file
		 	console.log("Transcoding from ", srcFileName, " to ", dstFileName);
		 	var proc = new ffmpeg({ source: srcFileName, nolog: true });
		 	// set the path to FFmpeg binary
		 	proc.setFfmpegPath(process.env['LAMBDA_TASK_ROOT'] + "/bin/ffmpeg");
			// set the size, format and filename
		 	proc
		 	.withSize('100%')
		 	.toFormat('mp4')
		 	.output(dstFileName)
		 	// set event handlers
		 	.on('end', function() {
		 		next();
		 	})
		 	.run();
		},
		function readfromdisk(next) {
			// read the file from disk
			console.log("Reading transcoded file ", dstFileName);
			var readFromDisk = fs.readFile(dstFileName, next);
		},
		function upload(response, next) {
			// upload the file to s3
			console.log("Uploading ", dstFileName, " to S3");
         		s3.putObject( { Bucket: dstBucket, Key: dstKey, Body: response }, next);
		}
		], function (err) {
			if (err) {
				console.error(
					'Unable to resize ' + srcBucket + '/' + srcKey +
					' and upload to ' + dstBucket + '/' + dstKey +
					' due to an error: ' + err
				);
			} else {
				console.log(
					'Successfully resized ' + srcBucket + '/' + srcKey +
					' and uploaded to ' + dstBucket + '/' + dstKey
				);
			}
			context.done();
		}
	);
};
