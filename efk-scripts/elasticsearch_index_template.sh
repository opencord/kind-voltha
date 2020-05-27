#!/bin/bash
# Add a template to adjust number of shards/replicas
# Note: If the security features are supported via X-Pack plugin and enable Role Based Access Control (RBAC)
# in Elasticsearch during efk deployment then provide the ELASTIC_USERNAME and ELASTIC_PASSWORD to access
TEMPLATE_NAME="my_template"
INDEX_PATTERN="logstash-*"
SHARD_COUNT=5
REPLICA_COUNT=0
ES_URL="http://localhost:9200"
ELASTIC_USERNAME=""
ELASTIC_PASSWORD=""

if [ "$ELASTIC_USERNAME" != "" -a "$ELASTIC_PASSWORD" != "" ]
then
curl -XPUT -u $ELASTIC_USERNAME:$ELASTIC_PASSWORD "$ES_URL/_template/$TEMPLATE_NAME" -H 'Content-Type: application/json' -d'{"index_patterns":['\""$INDEX_PATTERN"\"'],"settings":{"number_of_shards":'$SHARD_COUNT',"number_of_replicas":'$REPLICA_COUNT'}}'
else
curl -XPUT "$ES_URL/_template/$TEMPLATE_NAME" -H 'Content-Type: application/json' -d'{"index_patterns":['\""$INDEX_PATTERN"\"'],"settings":{"number_of_shards":'$SHARD_COUNT',"number_of_replicas":'$REPLICA_COUNT'}}'
fi
