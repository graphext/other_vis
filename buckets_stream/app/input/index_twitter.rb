require_relative '../elasticsearch/index_tweet'
require_relative '../twitter/monitor_tweets'

def index_twitter(terms, twitter_profile_ids, tokens)
	monitor_tweets(terms, twitter_profile_ids, tokens) do |tweet|
		index_tweet(tweet, tweet[:type], 10)
	end
	index_tweet(nil, nil, 0)
end