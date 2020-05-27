#!/bin/bash
# Copyright 2020 Ciena Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script add a template to adjust number of shards/replicas
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
