#!/usr/bin/env ruby

require 'open-uri'
require 'mail'
require 'optparse'

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: pragpub2kindle.rb [options] [yyyy-mm]"
  options[:mailto] = nil
  opts.on('-t', '--mailto EMAIL', 'Send attachment to email address') do |email|
    options[:mailto] = email
  end
  options[:mailfrom] = nil
  opts.on('-f', '--mailfrom EMAIL', 'Send attachment from email address') do |email|
    options[:mailfrom] = email
  end
  options[:dir] = nil
  opts.on('-d', '--dir DIR', 'Directory to save files') do |dir|
    options[:dir] = dir
  end
  opts.on('-h', '--help', 'Display this screen') do
    puts opts
    exit
  end
end

optparse.parse!

mandatory = [:mailto, :mailfrom]
missing = mandatory.select{ |param| options[param].nil? }
if not missing.empty?
  puts "Missing options: #{missing.join(', ')}"
  puts optparse
  exit
end

dir = options[:dir] || Dir.getwd
if (!(File.directory?(dir) && File.writable?(dir)))
  puts "Directory not valid or not writable: #{dir}"
  puts optparse
  exit
end

if ARGV.length == 1
  year_month = ARGV.first
  if !year_month.match(/\d{4}-\d{2}/)
    puts "Invalid date format: #{year_month}"
    puts optparse
    exit
  end
else
  year = Time.now.strftime("%Y")
  month = Time.now.strftime("%m")
  year_month = "#{year}-#{month}"
end

filename = "pragpub-#{year_month}.mobi"
year = year_month[0..3]

url = "http://magazines.pragprog.com/#{year}/#{filename}"
filepath = File.join(dir, filename)

if File.exists?(filepath)
  puts "#{filename} already exists"
else
  puts "Downloading #{filename}..."
  open(filepath, 'wb') do |file|
    file << open(url).read
  end
  mail_to = options[:mailto]
  mail_from =  options[:mailfrom]
  puts "Sending #{filename} to #{mail_to}..."
  mail = Mail.new
  mail.to = mail_to
  mail.from = mail_from
  mail.subject = filename
  mail.attachments[filename] = {
    :mime_type => 'application/x-mobipocket-ebook',
    :content => File.read(filepath)
  }
  mail.deliver!
end
