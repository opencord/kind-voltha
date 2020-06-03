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

# This script sets up a watch with information that is valuable when
# developing voltha with k8s
SCRIPTPATH="$( cd "$(dirname "$0")" || return  >/dev/null 2>&1 ; pwd -P )"

if ! command -v kubectl >/dev/null 2>&1; then
    >&2 echo "ERROR: 'kubectl' not in \$PATH"
    exit 1
fi

echo "Kind (client): $(kind version)"
kubectl version -o json | jq -r '"Kubernetes (client/server): "+.clientVersion.gitVersion+"/"+.serverVersion.gitVersion'
helm version --template 'Helm: (client/server): {{ (index . "Client").SemVer }}/{{ (index . "Server").SemVer }}{{ printf "\n"}}'

echo -n "Voltctl: (client/server): "
if ! command -v voltctl >/dev/null 2>&1; then
    echo "'voltctl' not in \$PATH"
else
    CLIENT=$(voltctl version --clientonly -o json | jq -r '"v"+.version')
    JSON=$(voltctl version -o json 2>&1)
    if [ "$?" -eq 0 ]; then
        echo "$CLIENT/$(echo "$JSON" | jq -r '"/v"+.cluster.version' 2>&1)"
    else
        echo "$CLIENT/$JSON"
    fi
fi
echo
kubectl get --all-namespaces pods,svc,configmap | grep -v kube-system
echo
kubectl  describe --all-namespaces  pods | grep Image: | grep '\(voltha\|bbsim\)' | sed -e "s/^ *//g" -e "s/: */: /g"
echo
echo "DB SIZE: $("$SCRIPTPATH/etcd-db-size.sh")"
echo
PIDS=$(pgrep -f "etcd --name etcd")
if [ -z "$PIDS" ]; then
    echo "RSS SIZE: N/A"
else
    echo "RSS SIZE: $(ps -ho rss $PIDS | xargs numfmt --to=iec | tr '\n' ' ' )"
fi
