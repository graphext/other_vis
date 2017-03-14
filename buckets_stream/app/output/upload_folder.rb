require_relative 'S3'
require 'active_support'

def upload_folder(local_dir, remote_dir, tokens)
	filter_out = -> (path) { path[/\.map$/] }

	bucket = get_S3Bucket(
		tokens["aws_bucket"],
		tokens["aws_access_key_id"],
		tokens["aws_secret_access_key"]
	)

	files = Dir[File.expand_path('.')+"/#{local_dir}/**/**"]
	files.each_with_index do |path, i|
		next if File.directory?(path) || filter_out.call(path)

		filename = path.scan(/\/#{Regexp.escape(local_dir)}\/(.+)/).first.first

		puts "[#{i+1}/#{files.size}] Saving: #{filename}"
		save_to_S3Bucket(remote_dir+'/'+filename, IO.read(path), bucket)
	end

	puts "Files uploaded to: http://#{tokens["aws_bucket"]}/#{remote_dir}/index.html"
end