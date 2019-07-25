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

CONFIG_VER=1.4.0
SADIS_VER=3.1.0
OLT_VER=3.0.1
AAA_VER=1.9.0
DHCP_VER=1.6.0

TYPE=${TYPE:-minimal}

if [ "$TYPE" == "full" ]; then
    ONOS_API_PORT=${ONOS_API_PORT:-8182}
    ONOS_SSH_PORT=${ONOS_SSH_PORT:-8102}
else
    ONOS_API_PORT=${ONOS_API_PORT:-8181}
    ONOS_SSH_PORT=${ONOS_SSH_PORT:-8101}
fi

mkdir -p onos-files/onos-apps
echo "Downloading ONOS applications"
curl --fail -sSL https://repo.maven.apache.org/maven2/org/opencord/cord-config/$CONFIG_VER/cord-config-$CONFIG_VER.oar -o ./onos-files/onos-apps/cord-config-$CONFIG_VER.oar
curl --fail -sSL https://repo.maven.apache.org/maven2/org/opencord/sadis-app/$SADIS_VER/sadis-app-$SADIS_VER.oar -o ./onos-files/onos-apps/sadis-app-$SADIS_VER.oar
curl --fail -sSL https://repo.maven.apache.org/maven2/org/opencord/aaa-app/$AAA_VER/aaa-app-$AAA_VER.oar -o ./onos-files/onos-apps/aaa-app-$AAA_VER.oar
curl --fail -sSL https://repo.maven.apache.org/maven2/org/opencord/olt-app/$OLT_VER/olt-app-$OLT_VER.oar -o ./onos-files/onos-apps/olt-app-$OLT_VER.oar
curl --fail -sSL https://repo.maven.apache.org/maven2/org/opencord/dhcpl2relay-app/$DHCP_VER/dhcpl2relay-app-$DHCP_VER.oar -o ./onos-files/onos-apps/dhcpl2relay-app-$DHCP_VER.oar

until test $(curl -w '\n%{http_code}' --fail -sSL --user karaf:karaf -X POST -H Content-Type:application/octet-stream http://127.0.0.1:$ONOS_API_PORT/onos/v1/applications?activate=true --data-binary @./onos-files/onos-apps/cord-config-$CONFIG_VER.oar 2>/dev/null | tail -1) -eq 409; do echo "Installing 'CONFIG' ONOS application ..."; sleep 1; done
until test $(curl -w '\n%{http_code}' --fail -sSL --user karaf:karaf -X POST -H Content-Type:application/octet-stream http://127.0.0.1:$ONOS_API_PORT/onos/v1/applications?activate=true --data-binary @./onos-files/onos-apps/sadis-app-$SADIS_VER.oar 2>/dev/null | tail -1) -eq 409; do echo "Installing 'SADIS' ONOS application ..."; sleep 1; done
until test $(curl -w '\n%{http_code}' --fail -sSL --user karaf:karaf -X POST -H Content-Type:application/octet-stream http://127.0.0.1:$ONOS_API_PORT/onos/v1/applications?activate=true --data-binary @./onos-files/onos-apps/olt-app-$OLT_VER.oar 2>/dev/null | tail -1) -eq 409; do echo "Installing 'OLT' ONOS application ..."; sleep 1; done
until test $(curl -w '\n%{http_code}' --fail -sSL --user karaf:karaf -X POST -H Content-Type:application/octet-stream http://127.0.0.1:$ONOS_API_PORT/onos/v1/applications?activate=true --data-binary @./onos-files/onos-apps/aaa-app-$AAA_VER.oar 2>/dev/null | tail -1) -eq 409; do echo "Installing 'AAA' ONOS application ..."; sleep 1; done
until test $(curl -w '\n%{http_code}' --fail -sSL --user karaf:karaf -X POST -H Content-Type:application/octet-stream http://127.0.0.1:$ONOS_API_PORT/onos/v1/applications?activate=true --data-binary @./onos-files/onos-apps/dhcpl2relay-app-$DHCP_VER.oar 2>/dev/null | tail -1) -eq 409; do echo "Installing 'DHCP L2 Relay' ONOS application ..."; sleep 1; done
until test $(curl -w '\n%{http_code}' --fail -sSL --user karaf:karaf -X POST -H Content-Type:application/json http://127.0.0.1:$ONOS_API_PORT/onos/v1/network/configuration --data @onos-files/olt-onos-netcfg.json 2>/dev/null | tail -1) -eq 200; do echo "Configuring VOLTHA ONOS ..."; sleep 1; done
until test $(curl -w '\n%{http_code}' --fail -sSL --user karaf:karaf -X POST -H Content-Type:application/json http://127.0.0.1:$ONOS_API_PORT/onos/v1/configuration/org.opencord.olt.impl.Olt --data @onos-files/olt-onos-olt-settings.json 2>/dev/null | tail -1) -eq 200; do echo "Enabling VOLTHA ONOS DHCP provisioning..."; sleep 1; done
until test $(curl -w '\n%{http_code}' --fail -sSL --user karaf:karaf -X POST -H Content-Type:application/json http://127.0.0.1:$ONOS_API_PORT/onos/v1/configuration/org.onosproject.net.flow.impl.FlowRuleManager --data @onos-files/olt-onos-enableExtraneousRules.json 2>/dev/null | tail -1) -eq 200; do echo "Enabling extraneous rules for ONOS..."; sleep 1; done
until test $(curl -w '\n%{http_code}' --fail -sSL --user karaf:karaf -X POST -H Content-Type:application/json "http://127.0.0.1:$ONOS_API_PORT/onos/v1/flows/of:0000000000000001?appId=env.voltha" --data @onos-files/dhcp-to-controller-flow.json 2>/dev/null | tail -1) -eq 201; do echo "Establishing DHCP packet-in flow ..."; sleep 1; done
