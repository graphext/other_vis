require 'json'
require_relative 'twitter/setup_twitter'
require_relative 'elasticsearch/setup_elastic'
require_relative 'elasticsearch/get_streams'
require_relative 'input/index_csv'
require_relative 'input/index_twitter'


system("cp -r www data/www")


config = JSON.parse(IO.read("data/config.json"))

setup_elastic(config["monitor"]["stopwords"])

setup_twitter(config["tokens"])

filename = config["monitor"]["file"]
terms = config["monitor"]["terms"]
twitter_profile_ids = config["monitor"]["twitter_profile_ids"]

if filename && filename.strip.length > 0
	index_csv(filename)
	get_streams(config["streams"], "data/www/data.json")
elsif terms && terms.length > 0
	index_twitter(terms, :terms)
elsif twitter_profile_ids && twitter_profile_ids.length > 0
	index_twitter(twitter_profile_ids, :ids)
end

exec("sh")

#system(%Q(/usr/bin/script -q -c '/usr/bin/tmux -f /app/.tmux.conf' /dev/null))