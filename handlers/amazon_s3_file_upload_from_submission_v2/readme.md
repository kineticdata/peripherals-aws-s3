# Amazon S3 File Upload From Submission
This handler uploads an existing file from a Kinetic Request CE submission to an Amazon S3 bucket.

## Parameters
[Region]
  Id of the region the inteded S3 server is located in (can also be configured as an info value).

[Bucket]
  Name of the bucket to upload to.

[Upload Path]
  The path in the s3 bucket to upload the file to.

[Access Control]
  The canned ACL to apply to the object. 
  
[Space Slug]
  Slug for the space the submission is in (can also be configured as an info value).

[Submission Id]
  Submission Id that the attachment is located on.

[Field Label]
  Field Label for the attachment field.

### Sample Configuration
Region:                       us-east-1
Bucket:                       sample-files
Upload Path:                  foo/bar/
Access Control:               private
Space Slug:
Submission Id:                73f18e87-b2b5-4f2c-b009-9eb8dcdd270c
Field Label:                  Attachment

## Results
[Public Url]
  A public url for the file that was just uploaded.

## Detailed Description
This handler creates and uploads content from an existing Request CE submission field value to an Amazon S3 bucket and then returns a public url of the successfully uploaded file. This is done by using an account's Access Key and Secret Access Key to authenticate with the Amazon S3 server and then uploading the file retrieved from Request CE and its content into the specified S3 bucket.
