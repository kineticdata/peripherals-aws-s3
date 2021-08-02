## Amazon S3 File Remove
This handler deletes and asset from an Amazon S3 bucket.

### Parameters
[Region]
  * Id of the region the intended S3 server is located in.

[Bucket]
  * Name of the bucket to delete from.

[Object Keys]
  * A comma separated list of Object identifiers.  Typically of the format path/to/asset.extension. Do not include the bucket name or a leading "/".

#### Sample Configuration
Region:                       us-east-1
Bucket:                       sample-files
File Name:                    foo/handler-test.txt

### Results
[Public Url]
  * A public url for the file that was just uploaded.

### Detailed Description
This handler deletes the provided asset from the provided Amazon S3 bucket.
This is done by using an account's Access Key and Secret Access Key to 
authenticate with the Amazon S3 server and then deleting the asset from the 
specified S3 bucket.

## Notes
Because **Object Keys** parameter splits the list on a ',' they are not valid in folder or file names.