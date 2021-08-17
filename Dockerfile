 FROM danbelden/ubuntu-elasticsearch51

USER root

WORKDIR /

 # Initial update
RUN apt-get update
## Install wget
RUN apt-get install -yq wget gnupg

RUN apt-get install -yq  apt-transport-https

#-------ELASTICSEARCH-------------

COPY elasticsearch.yml  /usr/share/elasticsearch-5.1.2/config/elasticsearch.yml

#------kibana-------------

# Kibana installation
RUN wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
RUN echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list
RUN apt-get update && apt-get install kibana

COPY kibana.yml /etc/kibana/kibana.yml

# Install curl utility just for testing
RUN apt-get update && \
	apt-get install -y curl

# Install vim for editing config file
RUN apt-get install -y nano


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

