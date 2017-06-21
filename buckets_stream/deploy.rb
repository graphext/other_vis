require 'json'


if ARGV.length != 1
	puts "ruby deploy.rb config_path"
	exit
end

config = JSON.parse(IO.read(ARGV[0]))

namespace = "bucketsstream" + '-' + config["client"] + '-' + config["project"]
namespace.gsub!(/[^\w\d]+/, '-').downcase!

system(%Q(kubectl create namespace #{namespace}))
exit unless $?.success?
system(%Q(kubectl create secret generic buckets-stream-secret --from-file="#{ARGV[0]}" --namespace #{namespace}))
exit unless $?.success?
system(%Q(kubectl apply --namespace=#{namespace} -f deployment.yaml))
exit unless $?.success?