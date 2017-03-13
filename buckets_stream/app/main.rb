require 'json'
require 'csv'
require 'httpclient'
require_relative 'fill_buckets/fill_buckets'
require_relative 'elasticsearch/setup_elastic'
require_relative 'elasticsearch/index_tweet'

config = JSON.parse(IO.read("data/config.json"))

setup_elastic(config["monitor"]["stopwords"])

i = 0
CSV.foreach('data/'+config["monitor"]["file"], headers: true, skip_blanks: true, col_sep: ',', encoding: 'UTF-8') do |r|
	tweet = r.to_h
	$stdout.write "\rIndexing... [#{i+=1}]"
	index_tweet(tweet)
end
index_tweet(nil, true)
$stdout.write "\rIndex completed [#{i+=1}]\n"


data = []
config["streams"].each_with_index do |stream, i|
	initial_date = (Time.now - (stream["time_window_size_mins"]*60)).to_i*1000
	final_date = Time.now.to_i*1000
	data << {
		title: stream["title"],
		data: fill_buckets('tweets', 'tweet', stream["filter"], initial_date, final_date, 'date', stream["buckets"], stream["time_bins_size_mins"]*60, stream["time_bins_size_mins"])
	}
end
system("cp -r www data/www")
IO.write("data/www/data.json", data.to_json)

exec("sh")

#system(%Q(/usr/bin/script -q -c '/usr/bin/tmux -f /app/.tmux.conf' /dev/null))