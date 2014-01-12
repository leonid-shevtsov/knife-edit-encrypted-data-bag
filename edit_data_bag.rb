#!/usr/bin/env ruby
# Edit Chef encrypted data bags.
# Initial credits to https://gist.github.com/4123044
# Heavily modified

unless ENV['EDITOR']
  puts "No EDITOR found. Try:"
  puts "export EDITOR=vim"
  exit 1
end

unless ARGV.count == 2
  puts "usage: #{$0} <data bag> <item name>"
  exit 1
end

require 'chef/encrypted_data_bag_item'
require 'json'
require 'tempfile'

data_bag = ARGV[0]
item_name = ARGV[1]
encrypted_path = "data_bags/#{data_bag}/#{item_name}.json"

data_bag_key_path = File.join(Dir.pwd, "data_bag_key")
unless File.exists? data_bag_key_path
  print "No data bag key found at #{data_bag_key_path}. Generate? [y/N] "
  if $stdin.gets.downcase.chomp=='y'
    puts 'Generating new data bag key. Don\'t forget to store it in a safe place!'
    `openssl rand -base64 512 >'#{data_bag_key_path}'`
  else
    exit 1
  end
end

secret = Chef::EncryptedDataBagItem.load_secret('data_bag_key')

decrypted_file = Tempfile.new ["#{data_bag}_#{item_name}",".json"]
at_exit { decrypted_file.delete }

if File.exists? encrypted_path
  encrypted_data = JSON.parse(File.read(encrypted_path))
  plain_data = Chef::EncryptedDataBagItem.new(encrypted_data, secret).to_hash
else
  puts "Cannot find #{File.join(Dir.pwd, encrypted_path)}; creating new data bag"
  plain_data ={'id' => item_name}
end

decrypted_file.puts JSON.pretty_generate(plain_data)
decrypted_file.close


begin
  new_data=nil
  system "#{ENV['EDITOR']} #{decrypted_file.path}"
  begin
    new_data = JSON.parse(File.read(decrypted_file.path))
  rescue JSON::ParserError => e
    puts "Error parsing data bag:\n\n#{e.message}.\n\nPress Return to continue editing the file."
    $stdin.gets
  end
end while !new_data

if new_data != plain_data
  encrypted_data = Chef::EncryptedDataBagItem.encrypt_data_bag_item(new_data, secret)
  FileUtils.mkdir_p "data_bags/#{data_bag}"
  File.write encrypted_path, JSON.pretty_generate(encrypted_data)
else
  puts 'No changes detected; not writing anything.'
end