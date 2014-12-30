#!/usr/bin/ruby

require 'rubygems'
require 'aws-sdk-core'
require 'aws-sdk'

def store_data_key(key_blob, key_id, key_plain=nil)
  fname = key_id + ".encrypted.key"
  STDERR.puts "NOTICE: Storing the encrypted key to #{fname}"
  f = File.new(fname, "w")
  f.write(key_blob)
  f.close
  unless(key_plain.nil?)
    fname = key_id + ".plain.key"
    STDERR.puts "Storing the plaintext key to #{fname}!"
    f = File.new(fname, "w")
    f.write(key_plain)
    f.close
  end
end

file_name = ARGV[0]
bucket    = ARGV[1]
unless !file_name.nil? and !bucket.nil? and
    File.exists? file_name
  raise "USAGE: #{$0} FILE BUCKET"
end

KEY_ARN = ENV['MASTER_KEY_ARN']
if(KEY_ARN.nil?)
  raise "Please provide a master key ARN via the MASTER_KEY_ARN environment variable"
end

kms = Aws::KMS::Client.new

data_key_resp = kms.generate_data_key(key_id: KEY_ARN,
                                      key_spec: "AES_256")

data_key_ciphertext = data_key_resp[:ciphertext_blob]
data_key_plaintext  = data_key_resp[:plaintext]
data_key_id         = data_key_resp[:key_id]
puts "Generated key has id #{data_key_id}"
store_data_key(data_key_ciphertext, file_name)

to_upload = File.new(file_name)

begin
  STDERR.puts "Uploading the encrypted data to S3"
  s3c = Aws::S3::Encryption::Client.new(encryption_key: data_key_plaintext)
  res = s3c.put_object(bucket: bucket,
                       key: File.basename(file_name),
                       body: to_upload)
  STDERR.puts "FINISHED DATA UPLOAD"
  STDERR.puts "Uploading the encrypted data key to S3"
  basic_client = s3c.client
  res = basic_client.put_object(bucket: bucket,
                                key: File.basename(file_name) + ".key",
                                body: data_key_ciphertext)
  STDERR.puts "FINISHED KEY UPLOAD"
rescue Aws::S3::Errors::ServiceError => e
  puts "upload failed: #{e}"
end

# Local variables:
# mode: ruby
# tab-width: 4
# indent-tabs-mode: nil
# end:
