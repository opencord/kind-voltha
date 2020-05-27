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

# This script cleanup indices created by log aggregation framework built on elasticsearch,kibana and fluentd within kubernetes.
# By default it deletes indices older than 3day's.
# Zero padded days using %d instead of %e
DAYSAGO=`date --date="3 days ago" +%Y%m%d`
ES_URL="http://127.0.0.1:9200"
ALLLINES=`/usr/bin/curl -s -XGET $ES_RUL/_cat/indices?v | egrep logstash`

echo
echo "THIS IS WHAT SHOULD BE DELETED FOR EFK:"
echo

echo "$ALLLINES" | while read LINE
do
  FORMATEDLINE=`echo $LINE | awk '{ print $3 }' | awk -F'-' '{ print $2 }' | sed 's/\.//g' ` 
  if [ "$FORMATEDLINE" -lt "$DAYSAGO" ]
  then
    TODELETE=`echo $LINE | awk '{ print $3 }'`
    echo "$ES_URL/$TODELETE"
  fi
done

echo
echo -n "if this make sence, Y to continue N to exit [Y/N]:"
read INPUT
if [ "$INPUT" == "Y" ] || [ "$INPUT" == "y" ] || [ "$INPUT" == "yes" ] || [ "$INPUT" == "YES" ]
then
  echo "$ALLLINES" | while read LINE
  do
    FORMATEDLINE=`echo $LINE | awk '{ print $3 }' | awk -F'-' '{ print $2 }' | sed 's/\.//g' `
    if [ "$FORMATEDLINE" -lt "$DAYSAGO" ]
    then
      TODELETE=`echo $LINE | awk '{ print $3 }'`
      /usr/bin/curl -XDELETE $ES_URL/$TODELETE
      sleep 1
      fi
  done
else 
  echo SCRIPT CLOSED BY USER, BYE ...
  echo
  exit
fi
