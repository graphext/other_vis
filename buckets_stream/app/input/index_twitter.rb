require_relative '../elasticsearch/index_tweet'
require_relative '../twitter/monitor_tweets'

def index_twitter(terms, type)
	monitor_tweets(terms, type) do |tweet|
		index_tweet(tweet)
	end
	index_tweet(nil, true)
end