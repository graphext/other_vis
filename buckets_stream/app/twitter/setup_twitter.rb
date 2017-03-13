require 'tweetstream'

def setup_twitter(tokens)
	TweetStream.configure do |c|
		c.consumer_key       = tokens["twitter_consumer_key"]
		c.consumer_secret    = tokens["twitter_consumer_secret"]
		c.oauth_token        = tokens["twitter_oauth_token"]
		c.oauth_token_secret = tokens["twitter_oauth_token_secret"]
		c.auth_method        = :oauth
	end
end