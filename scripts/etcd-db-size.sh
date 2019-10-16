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

# This script calculates the SIZE of the ETCD database

set -o pipefail

ETCD=$(kubectl -n voltha get pods 2>&1 | grep etcd-cluster | awk '{print $1}' | head -1)
if [ -z  "$ETCD" ]; then
    echo "N/A"
else
    VALUE=$(kubectl -n voltha exec -ti $ETCD -- sh -c 'ETCDCTL_API=3 etcdctl --command-timeout=10s endpoint status -w json' 2>/dev/null | tr -d '\r\n' | jq .[].Status.dbSize 2>/dev/null)
    if [ -z "$VALUE" ]; then
        echo "N/A"
    else
        numfmt --to=iec $VALUE
    fi
fi
