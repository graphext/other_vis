require_relative 'S3'
require 'active_support'

local_dir = "www"
remote_dir = "sidn/huawei"
filter_out = -> (path) { path[/\.map$/] }

bucket = get_S3Bucket(
	"embeddables.graphext.com",
	"***REMOVED***",
	"***REMOVED***"
)

files = Dir[File.expand_path(File.dirname(__FILE__))+"/#{local_dir}/**/**"]
files.each_with_index do |path, i|
	next if File.directory?(path) || filter_out.call(path)

	filename = path.scan(/\/#{local_dir}\/(.+)/).first.first

	puts "[#{i+1}/#{files.size}] Saving: #{filename}"
	save_to_S3Bucket(remote_dir+'/'+filename, IO.read(path), bucket)
end
