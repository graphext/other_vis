require 'tweetstream'
require 'elasticsearch'
require 'httpclient'
require 'pp'
require 'json'
require_relative 'elastic_conf'
require_relative '../partidos/partidos'

load_index

TweetStream.configure do |config|
	config.consumer_key       = '***REMOVED***'
	config.consumer_secret    = '***REMOVED***'
	config.oauth_token        = '***REMOVED***'
	config.oauth_token_secret = '***REMOVED***'
	config.auth_method        = :oauth
end

parties_terms = ['@Pablo_Iglesias_', '@marianorajoy','@sanchezcastejon', '@Albert_Rivera', '@agarzon', '@Sorayapp', 'Sáenz de Santamaría', 'Saenz de Santamaria', 'Rajoy', 'Pedro Sánchez', 'Pedro Sanchez', 'Pablo Iglesias', 'Albert Rivera', 'Alberto Garzón', 'Alberto Garzon', '@ahorapodemos', '@PPopular', '@PSOE', '@CiudadanosCs', '@iunida', 'PSOE', 'Unidos Podemos', '@ierrejon', 'Errejón', 'Errejon', 'Izquierda Unida']

hashtags = ['AVotar', '26J', 'elecciones26j', 'L6Elecciones', 'eleccionesA3', '26JOndaCero', 'elpais26J','hevotado', 'MiVotoCuenta','eleccionesL6', 'JornadaDeReflexion', 'EleccionesGenerales2016', 'Elecciones2016', 'EleccionesGenerales', '26JTVE']

$kill_hashtags_regex = Regexp.new(hashtags.map{|h| "([^\\w]|^)#?#{h}([^\\w]|$)"}.join('|'), Regexp::IGNORECASE)

$elastic_client = Elasticsearch::Client.new

def tweets2elasticsearch(tweets, type)
	bulk_tweets = tweets.map do |tweet|
		{ index:
			{
				_index: '26jelecciones',
				_type: type,
				_id: tweet[:id],
				data: tweet
			}
		}
	end
	$elastic_client.bulk body: bulk_tweets
end

def store_tweet(status, tweets_buffer, type)
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
		processed_text: status.full_text.gsub($kill_hashtags_regex, " "),
		date: status.created_at.iso8601,
		is_retweet: status.retweet?,
		rt_user_id: rt_user_id,
		rt_user_name: rt_user_name,
		rp_user_id: rp_user_id,
		rp_user_name: rp_user_name,
		location: location
	}

	tweet_h.merge!(extra)

	puts tweet_h

	tweets_buffer << tweet_h
	if tweets_buffer.length > 20
		tweets2elasticsearch(tweets_buffer, type)
		tweets_buffer.clear
	end
end

tweets_buffer = []

TweetStream::Client.new.track(hashtags.join(',')) do |status|
	store_tweet(status, tweets_buffer, 'hashtag')
end

# candidatos_set = TODOS_PARTIDOS_IDS.to_set
# TweetStream::Client.new.follow(TODOS_PARTIDOS_IDS) do |status|
# 	store_tweet(status, tweets_buffer, 'candidato') if candidatos_set.include? status.user.id
# end
