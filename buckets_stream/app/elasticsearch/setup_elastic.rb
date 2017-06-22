require 'json'
require 'httpclient'

def setup_elastic(stopwords)
	# Copy & start elasticsearch
	system("mv elasticsearch /data/") unless Dir.exist?('/data/elasticsearch')
	system("chmod 777 -R /data/elasticsearch")
	$stdout.write "Initiating elasticsearch... "

	pid = spawn("su elasticuser -s /bin/bash -c '/data/elasticsearch/bin/elasticsearch' &>/dev/null")

	begin
		HTTPClient.get("http://localhost:9200")
	rescue
		sleep 1
		retry
	end

	# Load index
	index_config = {
		mappings: {
			terms: {
				properties: {
					text: {
						type: "string",
						analyzer: "analyzer"
					},
					processed_text: {
						type: "string",
						analyzer: "processed_analyzer"
					},
					date: {
						type: "date"
					},
					created_at: {
						type: "date"
					}
				}
			},
			twitter_profile_ids: {
				properties: {
					text: {
						type: "string",
						analyzer: "analyzer"
					},
					processed_text: {
						type: "string",
						analyzer: "processed_analyzer"
					},
					date: {
						type: "date"
					},
					created_at: {
						type: "date"
					}
				}
			},
			file: {
				properties: {
					text: {
						type: "string",
						analyzer: "analyzer"
					},
					processed_text: {
						type: "string",
						analyzer: "processed_analyzer"
					},
					date: {
						type: "date"
					},
					created_at: {
						type: "date"
					}
				}
			}
		},
		settings: {
			index: {
				codec: "best_compression",
				number_of_shards: 2,
				number_of_replicas: 0
			},
			analysis: {
				filter: {
					"kill_hashtag": {
						"type": "pattern_replace",
						"pattern": "26J|elecciones26j",
						"replacement": ""
					},
					"kill_fillers": {
						"type": "pattern_replace",
						"pattern": " *_f_ *",
						"replacement": " ",
					},
					"shingle_filter": {
						"type":             "shingle",
						"min_shingle_size": 2,
						"max_shingle_size": 4,
						"output_unigrams": true,
						"filler_token": "_f_"
					}
				},
				analyzer: {
					analyzer: {
						tokenizer: "standard",
						filter: [
							"lowercase",
							"_stop_",
							"asciifolding"
						]
					},
					processed_analyzer: {
						tokenizer: "uax_url_email",
						filter: [
							"lowercase",
							#"kill_hashtag",
							"_stop_",
							"asciifolding",
							"shingle_filter",
							"kill_fillers",
							"trim"
						]
					}
				}
			}
		}
	}

	analysis = index_config[:settings][:analysis]
	stopwords.each do |st|
		analysis[:filter]["#{st}_stop"] = {
			type:       "stop",
			stopwords:  "_#{st}_"
		}
	end

	stopwords_filters = stopwords.map{|st|"#{st}_stop"}
	i = analysis[:analyzer][:analyzer][:filter].index("_stop_")
	analysis[:analyzer][:analyzer][:filter].insert(i+1, *stopwords_filters).delete_at(i)

	i = analysis[:analyzer][:processed_analyzer][:filter].index("_stop_")
	analysis[:analyzer][:processed_analyzer][:filter].insert(i+1, *stopwords_filters).delete_at(i)

	HTTPClient.put("http://127.0.0.1:9200/tweets", body: index_config.to_json)

	loop do
		status = JSON.parse(HTTPClient.get_content("http://localhost:9200/_cluster/health/tweets"))["status"]
		break if status == "green"
		sleep 1
	end

	puts "OK"

	pid
end
