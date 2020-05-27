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

# Using this script user,space and roles can be created
# The created user can access only those dashboards which are copied to the created spaces with created roles.
# Note: To create user and roles the security features should be supported via X-Pack plugin and enable Role Based Access Control (RBAC)
# in Elasticsearch during efk deployment
# ref: https://www.elastic.co/guide/en/kibana/current/api.html 
# https://www.elastic.co/guide/en/elasticsearch/reference/7.7/rest-apis.html
ES_URL="http://localhost:9200"
KB_URL="http://localhost:5601"
ELASTIC_USERNAME="elastic"
ELASTIC_PASSWORD="changeme"
NEW_USER_SPACES="operator"
NEW_USER_ROLES="operator"
NEW_USERNAME="operator"
NEW_PASSWORD="operator"

# Create a space with only dashboard settings enabled 
# Note: Any Other feature for the space can be enabled by removing the features from  "disabledFeatures" section 
curl -X POST -u $ELASTIC_USERNAME:$ELASTIC_PASSWORD "$KB_URL/api/spaces/space" -H "Content-Type: application/json" -H 'kbn-xsrf: true' -d'{"id":'\""$NEW_USER_SPACES"\"',"name":'\""$NEW_USER_SPACES"\"',"description":"This is '$NEW_USER_SPACES' space","color":"#aabbcc","initials":"","disabledFeatures":["discover","visualize","canvas","ml","maps","infrastructure","logs","apm","uptime","siem","dev_tools","advancedSettings","indexPatterns","savedObjectsManagement","monitoring"],"imageUrl":""}'

# Create new kibana role with 'NEW_USER_SPACES' with following privilages
# read only privilage for index-patterns, grant dashboard-only access with read only privilage to 'NEW_USER_SPACES'
# Note: Other features for the role can be enabled by adding the required features in feature section with privilage
curl -X PUT -u $ELASTIC_USERNAME:$ELASTIC_PASSWORD  "$KB_URL/api/security/role/$NEW_USER_ROLES" -H 'kbn-xsrf: true' -H 'Content-Type:application/json' -d'{"metadata":{"version":1},"elasticsearch":{"cluster":[],"indices":[{"names":["logstash*"],"privileges":["read"]}]},"kibana":[{"base":[],"feature":{"dashboard":["read"]},"spaces":['\""$NEW_USER_SPACES"\"']}]}'

# Create user with 'NEW_USER_ROLES'
# Note: Other roles for the user can be enabled by adding the required roles in roles section.
curl -X POST -u $ELASTIC_USERNAME:$ELASTIC_PASSWORD "$ES_URL/_security/user/$NEW_USERNAME?pretty" -H 'Content-Type: application/json' -d'{"password":'\""$NEW_PASSWORD"\"',"roles":['\""$NEW_USER_ROLES"\"'],"metadata":{"intelligence":7}}'
