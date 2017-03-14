require_relative '../elasticsearch/index_tweet'
require_relative '../twitter/monitor_tweets'

def index_twitter(terms, type, tokens)
	monitor_tweets(terms, type, tokens) do |tweet|
		index_tweet(tweet, 10)
	end
	index_tweet(nil, 0)
end