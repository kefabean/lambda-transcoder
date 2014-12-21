process.env['PATH'] = process.env['PATH'] + ':' + process.env['LAMBDA_TASK_ROOT'];
var aws = require('aws-sdk');
var s3 = new aws.S3({apiVersion: '2006-03-01' });
var sns = new aws.SNS();
var ffmpeg = require('fluent-ffmpeg');
var async = require('async');
// use external s3Stream module to stream to s3 and keep memory footprint low
var s3Stream = require('s3-upload-stream')(new aws.S3());


exports.handler = function(event, context) {
	// write event to console log
	console.log(JSON.stringify(event, null, '  '));

	// get s3 object info from event
	var srcBucket   = event.Records[0].s3.bucket.name;
	var srcKey      = event.Records[0].s3.object.key;
	var dstBucket   = srcBucket + "-transcoded";
	var dstKey      = srcKey + ".mp4";

	// validate source and destination buckets are different
	if (srcBucket == dstBucket) {
	  console.error("Destination bucket must not match source bucket.");
	  return;
	}
	// infer input format
	var typeMatch = srcKey.match(/\.([^.]*)$/);
	if (!typeMatch) {
		console.error('unable to infer image type for key ' + srcKey);
		context.done(null,''); 
		return;
	}
	var imageType = typeMatch[1];
	if (imageType != "avi") {
		console.log('skipping non-avi file ' + srcKey);
		context.done(null,'');
		return;
	}

	async.waterfall( [
		function transform(next) {
		 	// set source s3 object
		 	console.log("Getting object from S3: ", srcKey);
			var sourceStream = s3.getObject({ Bucket: srcBucket, Key: srcKey }).createReadStream();

			// set target s3 object
			var targetStream = s3Stream.upload({
  				Bucket: dstBucket,
  				Key: dstKey,
  				StorageClass: "REDUCED_REDUNDANCY"
			});
			targetStream.on('uploaded', function() {
				next();
			});

		 	// transcode file
		 	console.log("Transcoding object");
		 	var proc = new ffmpeg(sourceStream);

		 	// set path to FFmpeg binary
		 	proc.setFfmpegPath(process.env['LAMBDA_TASK_ROOT'] + "/bin/ffmpeg");

			// set size, format, target stream, options that allow mp4 streaming and event handlers
		 	proc
		 	.withSize('100%')
		 	.toFormat('mp4')
			.outputOptions('-movflags frag_keyframe+empty_moov')
		 	.output(targetStream)
			// start transcode
		 	.run();
		},
		function deleteOriginal(next) {
			// delete original object once transcoding complete
			s3.deleteObject({ Bucket: srcBucket, Key: srcKey }, next());
		},
		function getVideoUrl(next) {
			// get url to transcoded object
			s3.getSignedUrl('getObject', {Bucket: dstBucket, Key: dstKey, Expires: 600}, function(err, url) {
				next(null, url);
			});
		},
		function notifyUsers(url, next) {
			var messageParams = {
				Message: 'Video available for download here: ' + url,
				Subject: 'Motion detected from kefa-camera',
				TopicArn: 'arn:aws:sns:eu-west-1:089261358639:kefa-camera'
			};
			sns.publish(messageParams, next);
		}
		], function (err, data) {
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
