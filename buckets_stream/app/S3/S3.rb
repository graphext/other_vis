require 'fog/aws'
require 'mime-types'
require 'active_support'

# needed gems: fog-aws, mime-types

def get_S3Bucket(name, id, key)
	bucket = Fog::Storage.new(
		provider: "AWS",
		aws_access_key_id: id,
		aws_secret_access_key: key,
		region: "eu-central-1"
	).directories.get(name)
end

def save_to_S3Bucket(name, content, bucket)
	# IO.write(name, content)
	# return

	mime = MIME::Types.type_for(name).first
	mime = mime.content_type if mime

	bucket.files.create(
		key: name,
		body: ActiveSupport::Gzip.compress(content, Zlib::BEST_COMPRESSION),
		public: true,
		content_type: mime,
		content_encoding: "gzip",
		cache_control: "public, max-age=3600"
	)
end
