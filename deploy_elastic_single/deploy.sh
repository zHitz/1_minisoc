#!/bin/bash
cat << "EOF"

██╗  ██╗██╗███████╗███████╗ ██████╗     ██████╗██╗   ██╗██████╗ ███████╗██████╗ ███████╗ ██████╗  ██████╗
██║  ██║██║██╔════╝██╔════╝██╔════╝    ██╔════╝╚██╗ ██╔╝██╔══██╗██╔════╝██╔══██╗██╔════╝██╔═══██╗██╔════╝
███████║██║███████╗███████╗██║         ██║      ╚████╔╝ ██████╔╝█████╗  ██████╔╝███████╗██║   ██║██║     
██╔══██║██║╚════██║╚════██║██║         ██║       ╚██╔╝  ██╔══██╗██╔══╝  ██╔══██╗╚════██║██║   ██║██║     
██║  ██║██║███████║███████║╚██████╗    ╚██████╗   ██║   ██████╔╝███████╗██║  ██║███████║╚██████╔╝╚██████╗
╚═╝  ╚═╝╚═╝╚══════╝╚══════╝ ╚═════╝     ╚═════╝   ╚═╝   ╚═════╝ ╚══════╝╚═╝  ╚═╝╚══════╝ ╚═════╝  ╚═════╝
                                                                                                         
EOF
# Ensure you are running this script as root or with equivalent privileges to configure kernel parameters.
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or with equivalent privileges."
  exit 1
fi
echo "---------------------------------------------------------------------------------------------------------------------"
echo "                                        Installing package need"
echo "---------------------------------------------------------------------------------------------------------------------"
# Install package need
apt install python3-pip
pip3 install python-dotenv requests

#Create file store data and config
echo "---------------------------------------------------------------------------------------------------------------------"
echo "                                        Create file store data and config"
echo "---------------------------------------------------------------------------------------------------------------------"
mkdir his-cybersoc-logs-data his-cybersoc-logs-config certs his-cybersoc-kibana-data his-cybersoc-logstash-config his-cybersoc-kibana-config
mkdir his-cybersoc-logstash-config/pipeline
cp config/kibana/* his-cybersoc-kibana-config
cp config/logstash/* his-cybersoc-logstash-config
#unzip config/elasticsearch/his-cybersoc-logs-config.zip
cp config/logstash/example.conf his-cybersoc-logstash-config/pipeline
chmod 777 -R *

echo "DATA_ES=$(pwd)/his-cybersoc-logs-data" >> .env
echo "CERTS=$(pwd)/certs" >> .env
echo "DATA_DASH=$(pwd)/his-cybersoc-kibana-data" >> .env
echo "CONFIG_LOGSTASH=$(pwd)/his-cybersoc-logstash-config" >> .env
echo "CONFIG_DASH=$(pwd)/his-cybersoc-kibana-config" >> .env
echo "CONFIG_ES=$(pwd)/his-cybersoc-logs-config" >> .env

echo "---------------------------------------------------------------------------------------------------------------------"
echo "                                        Configure kernel parameters for Elasticsearch"
echo "---------------------------------------------------------------------------------------------------------------------"
# Configure kernel parameters for Elasticsearch
sysctl -w vm.max_map_count=262144

# Save the configuration to /etc/sysctl.conf to apply it automatically on startup
echo "vm.max_map_count=262144" >> /etc/sysctl.conf
echo "---------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------"
# Check if the script has enough arguments
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <elastic_version>"
  exit 1
fi

# Retrieve arguments from the command line
STACK_VERSION="$1"
#PROJECT_NAME="$2"

echo "STACK_VERSION=$STACK_VERSION" >> .env
echo "---------------------------------------------------------------------------------------------------------------------"
echo "                                        Pull images"
echo "---------------------------------------------------------------------------------------------------------------------"
# Pull Elasticsearch and Kibana images from Docker Hub
docker pull docker.elastic.co/elasticsearch/elasticsearch:"$STACK_VERSION"
docker pull docker.elastic.co/kibana/kibana:"$STACK_VERSION"
docker pull docker.elastic.co/logstash/logstash:"$STACK_VERSION"
echo "---------------------------------------------------------------------------------------------------------------------"
echo "                                        Create folder config for Elasticsearch"
echo "---------------------------------------------------------------------------------------------------------------------"
# Create folder config for Elasticsearch
docker run --name es-example -d -it docker.elastic.co/elasticsearch/elasticsearch:"$STACK_VERSION"
docker cp es-example:/usr/share/elasticsearch/config his-cybersoc-logs-config
#mv his-cybersoc-logs-config/config/* his-cybersoc-logs-config
echo "
cluster.name: "mini_soc-cluster"
network.host: his-cybersoc-logs
node.name: his-cybersoc-logs

bootstrap.memory_lock: true

xpack.monitoring.collection.enabled: true
ingest.geoip.downloader.enabled: true

xpack.security.enrollment.enabled: true
xpack.security.enabled: true
xpack.security.http.ssl.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.http.ssl.key: /usr/share/elasticsearch/config/certs/his-cybersoc-logs.key
xpack.security.http.ssl.certificate: /usr/share/elasticsearch/config/certs/his-cybersoc-logs.crt
xpack.security.http.ssl.certificate_authorities: /usr/share/elasticsearch/config/certs/ca/ca.crt

xpack.security.transport.ssl.key: /usr/share/elasticsearch/config/certs/his-cybersoc-logs.key
xpack.security.transport.ssl.certificate: /usr/share/elasticsearch/config/certs/his-cybersoc-logs.crt
xpack.security.transport.ssl.certificate_authorities: /usr/share/elasticsearch/config/certs/ca/ca.crt
" > his-cybersoc-logs-config/config/elasticsearch.yml
docker rm -f es-example

# Create Network
docker network create siem_net
echo "---------------------------------------------------------------------------------------------------------------------"
# Deploy the Elasticsearch and Kibana stack using Docker Compose
#docker compose -p "$PROJECT_NAME" up -d
cat << "EOF"

██████╗  ██████╗ ██████╗ ████████╗ █████╗ ██╗███╗   ██╗███████╗██████╗ 
██╔══██╗██╔═══██╗██╔══██╗╚══██╔══╝██╔══██╗██║████╗  ██║██╔════╝██╔══██╗
██████╔╝██║   ██║██████╔╝   ██║   ███████║██║██╔██╗ ██║█████╗  ██████╔╝
██╔═══╝ ██║   ██║██╔══██╗   ██║   ██╔══██║██║██║╚██╗██║██╔══╝  ██╔══██╗
██║     ╚██████╔╝██║  ██║   ██║   ██║  ██║██║██║ ╚████║███████╗██║  ██║
╚═╝      ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝
                                                                                                                                  
EOF
echo "---------------------------------------------------------------------------------------------------------------------"
echo "                                        Create Portainer Stack"
echo "---------------------------------------------------------------------------------------------------------------------"
python3 create_stack.py
# Check if the stack was deployed successfully
if [ $? -eq 0 ]; then
  echo "The Elasticsearch and Kibana stack has been deployed and is running."
else
  echo "Deployment of the Elasticsearch and Kibana stack failed. Please check the logs for more information."
fi
