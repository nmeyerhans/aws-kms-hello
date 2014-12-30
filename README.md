# basic AWS KMS demo app #

Some simple Hello World code for AWS KMS using the Ruby SDK.

**Note** due to bugs, you need to use at least version 2.0.17 of
the AWS Ruby SDK. Otherwise this code will fail with exceptions
related to the conversion of StringIO to String objects inside the
SDK libraries

This code contains simple programs demonstrating the usage of the AWS
KMS API. Currently it contains programs to encrypt and decrypt data
for storage in S3. Refer to
[the AWS docs](http://docs.aws.amazon.com/kms/latest/developerguide/concepts.html)
for conceptual background.

## Getting started ##

First, create a *master key* and an S3 bucket using the AWS
console. Note the ARN of the master key, which will look something
like:

	arn:aws:kms:us-east-1:380657856821:key/fce47900-1522-4fcd-afb7-b84a343435fd

## Encrypting and uploading a file ##

	MASTER_KEY_ARN=*ARN* AWS_REGION=us-east-1 ./put.rb FILE BUCKET

This will perform the following actions:

1. Create a new *data key* in KMS
2. Encrypt the specified file with the new data key
3. Upload the encrypted file to the specified S3 bucket.
4. Upload an encrypted copy of the data key to S3 with a name based on
   the specified file name plus a ".key" suffix. It will be encrypted
   with the Master Key in KMS.

You can now inspect the contents of your S3 bucket using the S3
console.

## Downloading and decrypting a file ##

	AWS_REGION=us-east-1 ./get.rb FILE BUCKET

This will perform the following:

1. Download the encrypted copy of the data key by constructing an S3
   URL based on the provided bucket and file name.
2. Decrypt the data key by asking the AWS KMS to perform this action.
3. Download the encrypted data file from S3.
4. Decrypt the downloaded file data and store it to a local file.
