require 'tweetstream'
require 'pp'


def monitor_tweets(terms, type, &block)
	if type == :terms
		TweetStream::Client.new.track(terms.join(',')) do |status|
			_process_tweet(status, block)
		end
	elsif type == :ids
		ids_set = Set.new(terms)
		TweetStream::Client.new.follow(terms) do |status|
			_process_tweet(status, block) if ids_set.include? status.user.id
		end
	end
end


def _process_tweet(status, cb)
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
		location: location
	}

	tweet_h.merge!(extra)

	cb.call(tweet_h)
rescue
	pp "RESCUED:"
	pp tweet_h
end