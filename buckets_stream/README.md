# BUILD
```
docker build . -t buckets_stream
```

# EXPORT AND LOAD IMAGE IN OTHER MACHINE
```
docker save buckets_stream -o buckets_stream.tar
```
```
docker load -i buckets_stream.tar
```

# CONFIG
A file named **config.json** that must be located in the folder that is used as the container's volume. These are its main keys:
### client
Client name as string used in aws bucket name, google analytics events etc.
### project
Project name as string used in aws bucket name, google analytics events etc.
### tokens
Tokens required to access the Twitter Streaming API, AmazonWS and Google Analytics.
### monitor
Configuration related to data ingestion. Although 'terms' & 'twitter\_profile\_ids' options can coexist together, 'file' option cannot.
- **file**: A csv file name. The file must contain at least an 'id' column and a 'text' column.
- **terms**: Array of search terms in Twitter Streaming API, e.g. ["Novartis Pharma"].
- **twitter\_profile\_ids**: Array of user ids in Twitter Streaming API, e.g. [17226612].
- **stopwords**: Array of languages for which stopwords will be removed, e.g. ["spanish", "english"].
- **refresh_period_secs**: Interval in seconds that determines when new data points will be computed and browser will reload.

Every tweet will be stored in elasticsearch with a type corresponding with the way they were obtained: 'tweets/file', 'tweets/terms' and 'tweets/twitter\_profile\_ids'. This is useful when using the stream pre-filter explained later. E.g.:
```json
"filter": {
	"type": {"value": "twitter_profile_ids" }
}
```

### sections
Named ranges in the streamgraph.
An array with each section definition, e.g.:
```json
[{
	"name": "Apertura", "text": "Apertura de colegios electorales",
	"x0": "2017-03-14T19:15:00.000+01:00",
	"x1": "2017-03-14T19:20:00.000+01:00"
}]
```
### streams
An array with every streamgraph definition.
- **title**: Streamgraph title.
- **time_window_size_mins**: Size in minutes of X axis.
- **time_bins_size_mins**: Size in minutes of each bin.
- **filter**: Pre-filter that all tweets in all buckets must pass. Elasticsearch syntax.
- **buckets**: An array with bucket definitions.
    - **_name**: Bucket's name.
    - **_color**: Optional. If specified, the color used for its area.
    - **attribute name**: Every attribute that will be filtered. Its value can be either an array of *phrases* that will be ORed together or an object with 'should', 'must' and 'must_not' keys to create a more complex filter. See the example below.

```json
[{
	"title": "Competitors Engagement",
	"time_window_size_mins": 7200,
	"time_bins_size_mins": 180,
	"filter": {
		"bool": {
			"must": [
				{ "term": { "is_retweet": false } },
				{ "term": { "author.lang": "es" } },
				{ "type": { "value": "terms" } }
			]
    	}
	},
	"buckets": [
		{
	        "_name": "Novartis",
	        "_color": "#ff0000",
			"text": ["Novartis","NovartisPharma"]
		},
		{
			"_name": "Bayer",
			"text": {
				"should": ["BayerPharma","BayerEspana","Bayer"],
				"must_not": ["football", "club", "leverkusen", "champions"]
			}
		},
		{
			"_name": "Roche",
			"text": {
				"should": ["Roche","Roche_spain"],
				"must_not": ["ferrero roche"]
			}
		}
	]
}]
```

# RUN
Create a folder with a *config.json* (e.g. './data') and pass it as a volume:
```
docker run -it -v `pwd`/data:/home/user/data buckets_stream
```

