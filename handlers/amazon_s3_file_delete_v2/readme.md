## Amazon S3 File Remove
This handler deletes assets from an Amazon S3 bucket.

### Parameters
[Region]
  * Id of the region the intended S3 server is located in.

[Bucket]
  * Name of the bucket to delete from.

[Object Keys]
  * A comma separated list of Object identifiers.  Typically of the format _path/to/asset.extension_. Do not include the bucket name or a leading "/".

#### Sample Configuration
Region:                       us-east-1
Bucket:                       sample-files
Object Keys:                  foo/handler-test.txt,foo/pic.jpg

### Results
[Results]
  * An array of JSON objects.

### Detailed Description
This handler deletes 1 or more assets from the provided Amazon S3 bucket.
This is done by using an account's Access Key and Secret Access Key to 
authenticate with the Amazon S3 server and then deleting the asset from the 
specified S3 bucket.

## Notes
Because **Object Keys** parameter splits the list on a ',' they are not valid in folder or file names.