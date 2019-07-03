#!/bin/bash

# Copyright 2019 Ciena Corporation
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

TYPE=${TYPE:-minimal}
if [ "$TYPE" == "full" ]; then
    VOLTHA_API_PORT=${VOLTHA_API_PORT:-55556}
    VOLTHA_SSH_PORT=${VOLTHA_SSH_PORT:-5023}
else
    VOLTHA_API_PORT=${VOLTHA_API_PORT:-55555}
    VOLTHA_SSH_PORT=${VOLTHA_SSH_PORT:-5022}
fi

echo "Scaling down voltha-api-server and ofagent"
(set -x; kubectl scale --replicas=0 deployment -n voltha voltha-api-server ofagent)
echo "Waiting for PODS to be terminated"
echo -n "Waiting "
until [ $(kubectl -n voltha get pods -o name | grep -c voltha-api-server) -eq 0 ]; do echo -n "."; sleep 3; done
until [ $(kubectl -n voltha get pods -o name | grep -c ofagent) -eq 0 ]; do echo -n "."; sleep 3; done
echo " Terminated"

echo "Scaling up voltha-api-server and ofagent"
(set -x; kubectl scale --replicas=1 deployment -n voltha voltha-api-server ofagent)
echo "Waiting for PODS to be running"
echo -n "Waiting "
until [ $(kubectl -n voltha get pods | grep voltha-api-server | grep -c "2/2") -eq 1 ]; do echo -n "."; sleep 3; done
until [ $(kubectl -n voltha get pods | grep ofagent | grep -c "1/1") -eq 1 ]; do echo -n "."; sleep 3; done
echo " Running"

echo "Forward VOLTHA API port"
(set -x; screen -p 0 -X -S voltha-api-$TYPE  stuff $'\003')
(set -x; screen -dmS voltha-api-$TYPE kubectl port-forward -n voltha service/voltha-api $VOLTHA_API_PORT:55555)
echo "Forward VOLTHA SSH port"
(set -x; screen -p 0 -X -S voltha-ssh-$TYPE  stuff $'\003')
(set -x; screen -dmS voltha-ssh-$TYPE kubectl port-forward -n voltha service/voltha-cli $VOLTHA_SSH_PORT:5022)
