# docker build . -t buckets_stream
# docker run -it -v `pwd`/data:/home/user/data buckets_stream

FROM alpine
MAINTAINER Miguel Canton <miguel@graphext.com>

ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8
ENV TERM xterm
ENV ELASTICSEARCH_VERSION 2.3.5

RUN apk add --update --no-cache \
	openssl-dev curl openjdk8 \
	ruby ruby-dev \
	make g++ zlib-dev \
	tmux bash screen util-linux

RUN curl -L https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.25-r0/glibc-2.25-r0.apk -o glibc.apk \
	&& curl -L https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.25-r0/glibc-bin-2.25-r0.apk -o glibc-bin.apk \
	&& curl -L https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.25-r0/glibc-i18n-2.25-r0.apk -o glibc-i18n.apk

RUN apk add --no-cache --allow-untrusted \
		glibc.apk glibc-bin.apk glibc-i18n.apk \
	&& /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true \
	&& apk del glibc-i18n \
	&& rm *.apk

RUN gem install --no-rdoc --no-ri httpclient fog-aws activesupport mime-types tweetstream json:'~> 1.8'

RUN adduser -h /home/user -s /bin/bash -G root -D user
USER user
WORKDIR /home/user

RUN mkdir data
RUN curl -L https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-$ELASTICSEARCH_VERSION.tar.gz -o elasticsearch.tar.gz \
	&& tar -xzf elasticsearch.tar.gz \
	&& rm -rf elasticsearch.tar.gz \
	&& mv elasticsearch-$ELASTICSEARCH_VERSION elasticsearch

COPY www www
COPY app app
COPY tmux.conf .tmux.conf

VOLUME /home/user/data

#CMD bash -c "script -q -c 'tmux -f .tmux.conf'"
ENTRYPOINT ruby app/main.rb
