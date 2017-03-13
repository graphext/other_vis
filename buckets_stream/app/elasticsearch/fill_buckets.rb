require 'httpclient'
require 'time'
require 'pp'
require 'json'

def _get_filters_from_buckets(buckets)
	buckets_filters = buckets.reduce({}) do |hash, bucket|
		sub_filters = {
			"should" => [],
			"must" => [],
			"must_not" => []
		}

		bucket.reject{|field| field[0][0] == '_'}.each do |field|
			field[1].each do |type, v|
				v = type and type = "should" if v.nil?
				v = [v].flatten

				v.each do |term|
					occur = "match_phrase"
					#occur << "_phrase" if term.is_a?(String) && !term.index(' ').nil?
					sub_filters[type] << {
						occur => {
							field[0] => term
						}
					}
				end
			end
		end

		hash[bucket["_name"]] = {
			query: {
				bool: sub_filters
			}
		}
		hash
	end

	buckets_filters
end

def fill_buckets(index, type, query_filter, init_date, last_date, date_field, buckets, window_size, resolution = 1)
	puts "Pidiendo a elasticsearch buckets de #{window_size/resolution}s, para ser colapsados a buckets de #{window_size}s"

	query_filter = {match_all: {}} if query_filter.nil?

	query_hash = {
		size: 0,
		query: {
			filtered: {
				query: query_filter,
				filter: {
					range: {
						date_field => {
							gte: init_date,
							lte: last_date
						}
					}
				}
			}
		},
		aggs: {
			topics: {
				filters: {
					filters: _get_filters_from_buckets(buckets)
				},
				aggs: {
					points: {
						date_histogram: {
							field: date_field,
							interval: (window_size/resolution).to_s+'s',
							time_zone: "Europe\/Madrid",
							min_doc_count: 0
						}
					},
					top_results: {
						top_hits: {
							_source: {
								include: ["_id"]
							},
							size: 500,
							sort: [
								{
									date: {
										order: "desc"
									}
								}
							]
						}
					}
				}
			}
		}
	}

	puts query_hash.to_json

	endpoint = "http://localhost:9200/#{index}/#{type}/_search"
	response = JSON.parse(HTTPClient.post_content(endpoint, body: query_hash.to_json))

	buckets = response["aggregations"]["topics"]["buckets"].map do |name, bucket|
		{
			name: name,
			color: buckets.find{|b|b["_name"]==name}["_color"],
			points: bucket["points"]["buckets"].map do |point|
				{
					x: point["key"],
					y: point["doc_count"]
				}
			end,
			sum: bucket["doc_count"],
			tweetIds: bucket["top_results"]["hits"]["hits"].map{|t| t["_id"]}
		}
	end

	agg_points(buckets, (window_size/resolution)*1000, resolution)
end

def agg_points(buckets, msec_increment, group_size)
	min_max_epochs = []
	buckets.each do |bucket|
		next if bucket[:points].empty?
		min_max_epochs << bucket[:points].first[:x]
		min_max_epochs << bucket[:points].last[:x]
	end
	min_max_epochs.sort!
	min_epoch = min_max_epochs.first
	max_epoch = min_max_epochs.last

	buckets.each do |bucket|
		points = bucket[:points]

		reduced = []

		unless points.empty?
			it_epoch = points.last[:x]
			while it_epoch < max_epoch
				it_epoch += msec_increment
				points << { x: it_epoch, y: 0 }
			end

			points.reverse!

			it_epoch = points.last[:x]
			while it_epoch > min_epoch
				it_epoch -= msec_increment
				points << { x: it_epoch, y: 0 }
			end

			# Colapsar ventana de 'group_size' buckets a un bucket centrado en la mediana
			points.each_slice(group_size) do |points|
				middle = points[(points.length-1)/2]
				middle[:y] = points.reduce(0) { |sum, point| sum + point[:y] }
				reduced << middle
			end
		end

		reduced.each do |p| p[:x] = DateTime.strptime(p[:x].to_s, '%Q') end

		bucket[:points] = reduced.reverse
	end

	buckets
end
