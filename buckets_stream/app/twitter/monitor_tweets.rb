require 'tweetstream'
require 'pp'

def monitor_tweets(terms, twitter_profile_ids, tokens, &block)
	client = TweetStream::Client.new({
		consumer_key: tokens["twitter_consumer_key"],
		consumer_secret: tokens["twitter_consumer_secret"],
		oauth_token: tokens["twitter_oauth_token"],
		oauth_token_secret: tokens["twitter_oauth_token_secret"],
		auth_method: :oauth
	})
	events = [:on_anything, :on_control, :on_enhance_your_calm, :on_error, :on_inited, :on_limit, :on_no_data_received, :on_reconnect, :on_stall_warning, :on_status_withheld, :on_unauthorized, :on_user_withheld]
	events.each do |cb_name|
		client.send(cb_name) do |*args|
			puts "#{cb_name.to_s}: #{args}"
		end
	end

	ids_set = Set.new(twitter_profile_ids)
	term_regexes = terms.map{|t| /(?:[^\w]+|^)#{Regexp.escape(t)}(?:[^\w]+|$)/i }

	client.filter(track: terms.join(','), follow: twitter_profile_ids.join(',')) do |status|
		tweet = _process_tweet(status)
		text = tweet[:text]

		if ids_set.include?(tweet[:user][:id])
			tweet[:type] = :twitter_profile_ids
			block.call(tweet)
		end

		if term_regexes.any?{|re| text =~ re }
			tweet[:type] = :terms
			block.call(tweet)
		end
	end
end


def _process_tweet(status)
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

	tweet_h.merge(extra)
rescue
	pp "RESCUED:"
	pp tweet_h
end