FROM danbelden/ubuntu-elasticsearch51
# FROM  danbelden/ubuntu-kibana51
USER root

WORKDIR /

 # Initial update
RUN apt-get update
## Install wget
RUN apt-get install -yq wget gnupg

RUN apt-get install -yq  apt-transport-https

# Install curl utility just for testing
RUN apt-get update && \
	apt-get install -y curl

#-------ELASTICSEARCH-------------

COPY elasticsearch.yml  /usr/share/elasticsearch-5.1.2/config/elasticsearch.yml

#------kibana-------------

# Set env specific configs
ENV DEBIAN_FRONTEND noninteractive
ENV KIBANA_VERSION 5.1.2

# Update core dependencies
RUN apt-get update
RUN apt-get install -y --no-install-recommends apt-utils

# Update dependencies ready
RUN apt-get upgrade -y

# Add required dependencies for install
RUN apt-get install -y --no-install-recommends ca-certificates wget apt-transport-https

# Install gosu to enable "Easy root stepdown"
ENV GOSU_VERSION 1.7
RUN set -x
RUN rm -rf /var/lib/apt/lists/*
RUN wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)"
RUN wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc"
RUN export GNUPGHOME="$(mktemp -d)"
RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu
RUN rm -r /usr/local/bin/gosu.asc
RUN chmod +x /usr/local/bin/gosu
RUN gosu nobody true

# Install tini to enable "signal processing and zombie killing"
ENV TINI_VERSION v0.9.0
RUN set -x
RUN wget -O /usr/local/bin/tini "https://github.com/krallin/tini/releases/download/$TINI_VERSION/tini"
RUN wget -O /usr/local/bin/tini.asc "https://github.com/krallin/tini/releases/download/$TINI_VERSION/tini.asc"
RUN export GNUPGHOME="$(mktemp -d)"
RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 6380DC428747F6C393FEACA59A84159D7001A4E5
RUN gpg --batch --verify /usr/local/bin/tini.asc /usr/local/bin/tini
RUN rm -r /usr/local/bin/tini.asc
RUN chmod +x /usr/local/bin/tini 
RUN tini -h

# Add the elastic GPG key for apt-get
# https://artifacts.elastic.co/GPG-KEY-elasticsearch
RUN set -ex;
RUN export GNUPGHOME="$(mktemp -d)";
RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "46095ACC8548582C1A2699A9D27D666CD88E42B4";
RUN gpg --export "46095ACC8548582C1A2699A9D27D666CD88E42B4" > /etc/apt/trusted.gpg.d/elastic.gpg;
RUN apt-key list

# Add the relevant kibana source url for apt-get
# https://www.elastic.co/guide/en/kibana/5.1/deb.html
RUN wget https://artifacts.elastic.co/downloads/kibana/kibana-5.1.2-amd64.deb
RUN sha1sum kibana-5.1.2-amd64.deb
RUN dpkg -i kibana-5.1.2-amd64.deb



# # Set ownership to the kibana user
# RUN set -x
# RUN chown -R kibana:kibana /etc/kibana
# RUN rm -rf /var/lib/apt/lists/*

# # Correct kibana configuration issues
# # the default "server.host" is "localhost" in 5+
# # ensure the default configuration is useful when using --link
# RUN sed -ri "s!^(\#\s*)?(server\.host:).*!\2 '0.0.0.0'!" /etc/kibana/kibana.yml
# RUN sed -ri "s!^(\#\s*)?(elasticsearch\.url:).*!\2 'http://elasticsearch:9200'!" /etc/kibana/kibana.yml
# RUN grep -q "^elasticsearch\.url: 'http://elasticsearch:9200'\$" /etc/kibana/kibana.yml

# # Add the kibana executable to the root PATH
# ENV PATH /usr/share/kibana/bin:$PATH

# Purge now redundant packages
RUN apt-get purge -y --auto-remove ca-certificates wget apt-transport-https
RUN rm -rf /var/lib/apt/lists/*

# # Copy the entrypoint executable
# COPY entrypoint.sh /
# RUN chmod +x /entrypoint.sh

COPY kibana.yml  /etc/kibana/kibana.yml

#------filebeat------------


RUN wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
RUN echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list
RUN apt-get update && apt-get install filebeat

COPY filebeat.yml /etc/filebeat/filebeat.yml

#------nomad-------------

#Run ssh and dependencies 
RUN apt-get update && apt install  openssh-server -y
# RUN apt-get install apt-transport-https ca-certificates curl
RUN apt-get install -y init-system-helpers 
RUN apt-get install -y libc6
RUN apt-get install -y pipexec
RUN apt-get install -y procps
RUN apt-get install  -qq -y software-properties-common

#Install Nomad



RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
RUN apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

RUN apt-get update 
RUN apt-get -y install nomad

COPY python.nomad /etc/nomad/
# COPY agent.hcl /etc/nomad/
COPY hellorun.sh /etc/nomad/scripts/hellorun.sh

RUN chmod +x /etc/nomad/scripts/hellorun.sh
RUN chmod +x /etc/nomad/python.nomad

#----supervisord------------

# supervisor installation &&
# create directory for child images to store configuration in
RUN apt-get update && \
    apt-get -y install supervisor && \
  mkdir -p /var/log/supervisor && \
  mkdir -p /etc/supervisor/conf.d


COPY supervisor.conf /etc/supervisor/conf.d/

COPY kibana.yml  /etc/kibana/kibana.yml

#Open Right ports
EXPOSE 9200 
EXPOSE 5601
EXPOSE 9300
EXPOSE 4646
EXPOSE 8500
EXPOSE 9001


#Artifically generate logs 

RUN touch /var/log/python-test.log

  # ---------------RUN SUPERVISOR----------------------

# # CMD ["/usr/bin/supervisord"]
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisor.conf"]

