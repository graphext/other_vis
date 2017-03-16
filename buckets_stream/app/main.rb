require 'json'
require_relative 'elasticsearch/setup_elastic'
require_relative 'elasticsearch/get_streams'
require_relative 'elasticsearch/close_elastic'
require_relative 'input/index_csv'
require_relative 'input/index_twitter'
require_relative 'output/prepare_web'
require_relative 'output/escape_filename'
require_relative 'output/upload_folder'

config = JSON.parse(IO.read("data/config.json"))

prepare_web(config)

elastic_pid = setup_elastic(config["monitor"]["stopwords"])

threads = []

trap "SIGINT" do
	puts "\nExiting..."
	threads.each{|th| th.exit }
end

filename = config["monitor"]["file"]
terms = config["monitor"]["terms"]
twitter_profile_ids = config["monitor"]["twitter_profile_ids"]

remote_dir = escape_filename(config["client"]) +'/'+ escape_filename(config["project"])

if filename && filename.strip.length > 0
	index_csv(filename)
	get_streams(config["streams"], "data/www/data.json")
	upload_folder("data/www", remote_dir, config["tokens"])
else
	threads << Thread.new do
		loop do
			get_streams(config["streams"], "data/www/data.json")
			upload_folder("data/www", remote_dir, config["tokens"])
			sleep config["monitor"]["refresh_period_secs"]
		end
	end
	if terms && terms.length > 0
		threads << Thread.new{index_twitter(terms, :terms, config["tokens"])}
		sleep 1
	end
	if twitter_profile_ids && twitter_profile_ids.length > 0
		threads << Thread.new{index_twitter(twitter_profile_ids, :twitter_profile_ids, config["tokens"])}
	end
end

threads.each{|th| th.join }

#exec("sh")

close_elastic(elastic_pid)

#system(%Q(/usr/bin/script -q -c '/usr/bin/tmux -f /app/.tmux.conf' /dev/null))