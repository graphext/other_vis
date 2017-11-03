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
		tweet = status.to_h
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

File.open("tweets.jsonl", "w") do |f|
	monitor_tweets(["hija de puta", "zorra"], [], {"twitter_consumer_key" => "",
		"twitter_consumer_secret"=> "",
		"twitter_oauth_token"=> "",
		"twitter_oauth_token_secret"=> ""
	}) do |tweet|
		f.puts tweet.to_h.to_json
	end
end