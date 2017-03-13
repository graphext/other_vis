require_relative 'fill_buckets'

require 'time'
require 'json'
require 'pp'

def get_streams(streams, path)
	data = []
	streams.each_with_index do |stream, i|
		initial_date = (Time.now - (stream["time_window_size_mins"]*60)).to_i*1000
		final_date = Time.now.to_i*1000
		data << {
			title: stream["title"],
			data: fill_buckets('tweets', 'tweet', stream["filter"], initial_date, final_date, 'date', stream["buckets"], stream["time_bins_size_mins"]*60, stream["time_bins_size_mins"])
		}
	end

	IO.write(path, data.to_json)
end