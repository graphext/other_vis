
def prepare_web(config)
	system("cp -r www data/")

	index = IO.read("data/www/index.html")

	index.gsub!('__google_analytics_id__', config["tokens"]["google_analytics_id"])
	index.gsub!('__refresh_period_secs__', config["monitor"]["refresh_period_secs"].to_s)
	index.gsub!('__sections__', config["sections"].to_json)
	index.gsub!('__event_info__', "client:'#{config["client"]}', project:'#{config["project"]}'")

	IO.write("data/www/index.html", index)
end