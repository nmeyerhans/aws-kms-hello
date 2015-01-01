#!/usr/bin/ruby

require 'rubygems'
require 'aws-sdk-core'
require 'aws-sdk'
require 'yaml'
require 'base64'

REGION = 'us-east-1'

file = ARGV.shift
bucket = ARGV.shift
if(file.nil? or bucket.nil?)
  STDERR.puts "#{$0} FILE BUCKET"
  exit 1
end

def decrypt_data_key(blob)
  kms = Aws::KMS::Client.new(region: REGION)
  res = kms.decrypt(ciphertext_blob: blob)
  puts "Decrypted #{res[:plaintext].size} bytes of key data"
  return res[:plaintext]
end

def get_key(bucket, file)
  begin
    s3c = Aws::S3::Client.new(region: REGION)
    res = s3c.get_object(bucket: bucket,
                         key: file)
    puts "Got #{res[:body].size} bytes of encrypted key data"
    key_blob_strio = res[:body]
    key_blob = key_blob_strio.read
    decrypt_data_key(key_blob)
  rescue Aws::S3::Errors::ServiceError => e
    puts "S3 error: #{e}"
    exit 1
  end
end

def get_file(bucket, file, key)
  begin
    s3c = Aws::S3::Encryption::Client.new(encryption_key: key,
                                          region: REGION)
    res = s3c.get_object(bucket: bucket,
                     key: file)
    f = File.new(file, 'w')
    f.puts res[:body].read
  rescue Aws::S3::Errors::ServiceError => e
    puts "S3 error: #{e}"
    exit 1
  end
end

data_key = get_key(bucket, file + ".key")
get_file(bucket, file, data_key)

# Local variables:
# mode: ruby
# tab-width: 4
# indent-tabs-mode: nil
# end:
