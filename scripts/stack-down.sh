#!/usr/bin/env bash
# Copyright 2020 Open Networking Foundation
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

WITH_ONOS=no WITH_BBSIM=no WITH_ETCD=no WITH_KAFKA=no WITH_RADIUS=no CONFIG_SADIS==no ADAPTER_NS="$NAME" VOLTHA_NS="$NAME" ./voltha down
