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

# This script defragments the ETCD database to claim back space

kubectl -n voltha exec -ti $(kubectl -n voltha get pods | grep etcd-cluster | awk '{print $1}') -- sh -c 'ETCDCTL_API=3 etcdctl defrag'
