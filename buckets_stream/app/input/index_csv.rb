require 'csv'
require_relative '../elasticsearch/index_tweet'

def index_csv(filename)
	i = 0
	CSV.foreach('data/' + filename, headers: true, skip_blanks: true, col_sep: ',', encoding: 'UTF-8') do |r|
		tweet = r.to_h
		$stdout.write "\rIndexing... [#{i+=1}]"
		index_tweet(tweet, 1000)
	end
	index_tweet(nil, 0)
	$stdout.write "\rIndex completed\n"
end