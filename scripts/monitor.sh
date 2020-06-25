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
__COLS=$(($(tput cols) - 1))

echo -n "Kind (client): "
if ! command -v kind >/dev/null 2>&1; then
    echo "'kind' not in \$PATH"
else
    kind version | sed -E -e 's/^.*(v[0-9]+\.[0-9]+\.[0-9]+).*$/\1/'
fi

echo -n "Kubernetes (client/server): "
if ! command -v kubectl >/dev/null 2>&1; then
    echo "'kubectl' not in \$PATH"
else
    CLIENT=$(kubectl version --client -o json | jq -r '.clientVersion.gitVersion')
    SERVER=$(kubectl version -o json 2>/dev/null)
    if [ "$?" -ne 0 ]; then
        SERVER="ERROR"
    else
        SERVER=$(echo $SERVER | jq -r '.serverVersion.gitVersion')
    fi
    echo "$CLIENT/$SERVER"
fi

echo -n "Helm (client/server): "
if ! command -v helm >/dev/null 2>&1; then
    echo "'helm' not in \$PATH"
else
    CLIENT=$(helm version --client --short 2>/dev/null | sed -E -e 's/^.*(v[0-9]+\.[0-9]+\.[0-9]+).*$/\1/')
    MAJOR=$(helm version --client --short 2>/dev/null | sed -E -e 's/^.*v([0-9]+)\.[0-9]+\.[0-9]+.*$/\1/')
    if [ "$MAJOR" -le 2 ]; then
        SERVER=$(helm version --server --short 2>/dev/null | sed -E -e 's/^.*(v[0-9]+\.[0-9]+\.[0-9]+).*$/\1/')
        if [ -z "$SERVER" ]; then
            SERVER="ERROR"
        fi
        echo "$CLIENT/$SERVER"
    else
        echo "$CLIENT"
    fi
fi

echo -n "Voltha: (client/server): "
if ! command -v voltctl >/dev/null 2>&1; then
    echo "'voltctl' not in \$PATH"
else
    CLIENT=$(voltctl version --clientonly -o json | jq -r '"v"+.version')
    SERVER=$(voltctl version -o json 2>/dev/null)
    if [ -z "$SERVER" ]; then
        SERVER="ERROR"
    else
        SERVER=$(echo "$SERVER" | jq -r '"v"+.cluster.version')
    fi
    echo "$CLIENT/$SERVER"
fi
echo
kubectl get --all-namespaces pods,svc,configmap | grep -v kube-system | cut -c -$__COLS
echo
kubectl  describe --all-namespaces  pods | grep Image: | grep '\(voltha\|bbsim\)' | sed -e "s/^ *//g" -e "s/: */: /g" | sort -u | cut -c -$__COLS
echo
echo "DB SIZE: $("$SCRIPTPATH/etcd-db-size.sh")"
echo
PIDS=$(pgrep -f "etcd --name etcd")
if [ -z "$PIDS" ]; then
    echo "RSS SIZE: N/A"
else
    echo "RSS SIZE: $(ps -ho rss $PIDS | xargs numfmt --to=iec | tr '\n' ' ' )"
fi
