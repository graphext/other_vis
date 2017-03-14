require 'twitter'
require 'pp'

def monitor_tweets(terms, type, tokens, &block)
	client = Twitter::Streaming::Client.new do |c|
		c.consumer_key        = tokens["twitter_consumer_key"]
		c.consumer_secret     = tokens["twitter_consumer_secret"]
		c.access_token        = tokens["twitter_oauth_token"]
		c.access_token_secret = tokens["twitter_oauth_token_secret"]
	end

	if type == :terms
		client.filter(track: terms.join(',')) do |status|
			if status.is_a?(Twitter::Tweet)
				_process_tweet(status, type, block)
			else
				pp status
			end
		end
	elsif type == :twitter_profile_ids
		ids_set = Set.new(terms)
		client.filter(follow: terms.join(',')) do |status|
			_process_tweet(status, type, block) if status.is_a?(Twitter::Tweet) && ids_set.include?(status.user.id)
		end
	end
end


def _process_tweet(status, type, cb)
	location = status.geo.coordinates.join(',') unless status.geo.coordinates.nil?
	rt_user_id = status.retweeted_tweet.user.id if status.retweet?
	rt_user_name = status.retweeted_tweet.user.screen_name if status.retweet?
	rp_user_id = status.in_reply_to_user_id if status.reply?
	rp_user_name = status.in_reply_to_screen_name if status.reply?

	tweet_h = status.to_h
	tweet_h[:created_at] = status.created_at.iso8601

	extra = {
		id: status.id,
		author_id: status.user.id,
		author_name: status.user.screen_name,
		text: status.full_text,
		processed_text: status.full_text,
		date: status.created_at.iso8601,
		is_retweet: status.retweet?,
		rt_user_id: rt_user_id,
		rt_user_name: rt_user_name,
		rp_user_id: rp_user_id,
		rp_user_name: rp_user_name,
		location: location,
		type: type
	}

	tweet_h.merge!(extra)

	cb.call(tweet_h)
rescue
	pp "RESCUED:"
	pp tweet_h
end