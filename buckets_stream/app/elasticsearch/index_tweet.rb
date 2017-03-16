require 'httpclient'
require 'pp'

$body_req = ""
$buffer_size = 0
def index_tweet(tweet, type, nSize=0)
	if tweet
		#pp tweet
		$stdout.write "."
		$body_req += {
			index: {_index: "tweets", _type: type.to_s, _id: tweet["id"] || tweet[:id_str] || tweet["id_str"] }
		}.to_json + "\n" + tweet.to_json + "\n"
		$buffer_size += 1
	end

	if $body_req.length > 0 && $buffer_size >= nSize
		HTTPClient.post_content('http://localhost:9200/_bulk', body: $body_req)
		$body_req.clear
		$buffer_size = 0
	end
end
