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

watch '$HOME/kind-voltha/bin/kubectl get --all-namespaces pods,svc && echo "" \
    &&  kubectl  describe --all-namespaces  pods | grep Image: | grep voltha | sed -e "s/^ *//g" -e "s/: */: /g"  && echo "" \
    && echo "DB SIZE: $(./scripts/etcd-db-size.sh)" && echo "" \
    && echo "RSS SIZE: $(ps -eo rss,pid,cmd | grep /usr/local/bin/etcd | grep -v grep | cut -d\  -f1 | numfmt --to=iec)"'
