# Kubernetes Kind VOLTHA Test Environment
This repository describes how to deploy a 4 node (one control plane and

## Prerequisites
You must have both Docker and the Go programming language install for this
test environment to function. How to get these working is beyond the scope
of this document.

## Fetch Tools
```bash
export GOPATH=$(pwd)
mkdir -p $GOPATH/bin
curl -o $GOPATH/bin/kubectl -sSL https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/$(go env GOHOSTOS)/$(go env GOARCH)/kubectl
curl -o $GOPATH/bin/kind \
	-sSL https://github.com/kubernetes-sigs/kind/releases/download/v0.4.0/kind-$(go env GOHOSTOS)-$(go env GOARCH)
curl -o $GOPATH/bin/voltctl \
	-sSL https://github.com/ciena/voltctl/releases/download/0.0.5-dev/voltctl-0.0.5_dev-$(go env GOHOSTOS)-$(go env GOARCH)
curl -sSL https://git.io/get_helm.sh | USE_SUDO=false HELM_INSTALL_DIR=$(go env GOPATH)/bin bash
chmod 755 $GOPATH/bin/kind $GOPATH/bin/voltctl $GOPATH/bin/kubectl
export PATH=$(go env GOPATH)/bin:$PATH
```

## Minimal v. Full
This files contained in this repository can be used to deploy either a minimal
or full voltha deployment. The difference is characterized in the following
table:

| RESOURCE                | MINIMAL       | FULL                      |
| ----------------------- | ------------- | ------------------------- |
| K8s Control Plane Nodes | 1             | 1                         |
| K8s Workers             | 2             | 3                         |
| EtcdOperator Components | Operator only | Operator, Backup, Restore |
| EtcdCluster             | 1 Member      | 3 Members                 |

Throughout this `README.md` file deployment and configuration files are
referenced in the form **$TYPE-cluster.cfg** and **$TYPE-values.yaml**.
Depending on which type of deloyment you wish to install replace **$TYPE**
with either **minimal** or **full**. If you set the environment variable to the
desired deployment type, example below, then the commands can be executed via
a simply copy and paste to your command line.
```bash
export TYPE=minimal
```

## TL;DR
OK, if you really don't care how it starts and you just wanted started. After
cloning the repository and making sure you have Go and Docker available, just
execute `./voltha up` and the minimal cluster should start.

To remove voltha use `./voltha down`

![Demo @ Speed](./resources/kind-voltha.gif "Demo @ Speed")
_NOTE: Shown significantly sped up (20x), actual install was about 8 minutes._

### `voltha up` Configuration Options
This options should be set using environment variables, thus to start VOLTHA
with the BBSIM POD you could use the following command:
```
WITH_BBSIM=yes voltha up
```

| OPTION                          | DEFAULT                      | DESCRIPTION                                                                         |
| ------------------------------- | ---------------------------- | ----------------------------------------------------------------------------------- |
| `TYPE`                          | minimal                      | `minimal` or `full` and determines number of cluster nodes and etcd cluster members |
| `NAME`                          | TYPE                         | Name of the KinD Cluster to be created                                              |
| `DEPLOY_K8S`                    | yes                          | Should the KinD Kubernetes cluster be deployed?                                     |
| `JUST_K8S`                      | no                           | Should just the KinD Kubernetes cluster be depoyed? (i.e. no VOLTHA)                |
| `WITH_BBSIM`                    | no                           | Should the BBSIM POD be deployed?                                                   |
| `WITH_ONOS`                     | yes                          | Should `ONOS` service be deployed?                                                  |
| `WITH_RADIUS`                   | no                           | Should `freeradius` service be deployed?                                            |
| `WITH_TP`                       | yes                          | Install the ONOS image that support Tech Profiles                                   |
| `WITH_TIMINGS`                  | no                           | Outputs duration of various steps of the install                                    |
| `CONFIG_SADIS`                  | no                           | Configure SADIS entries into ONOS, if WITH_ONOS set (see SADIS Configuration        |    
| `INSTALL_ONOS_APPS`             | no                           | Replaces/installs ONOS OAR files in onos-files/onos-apps                            |
| `SKIP_RESTART_API`              | no                           | Should the VOLTHA API service be restarted after install to avoid known bug?        |
| `INSTALL_KUBECTL`               | yes                          | Should a copy of `kubectl` be installed locally?                                    |
| `INSTALL_HELM`                  | yes                          | Should a copy of `helm` be installed locallly?                                      |
| `USE_GO`                        | yes                          | Should the Go[lang] version of the OpenOLT adapter be used?                         |
| `ONOS_TAG`                      |                              | Used to override the default image tag for the ONOS docker image                    |
| `VOLTHA_LOG_LEVEL`              | WARN                         | Log level to set for VOLTHA core processes                                          |
| `VOLTHA_CHART`                  | onf/voltha                   | Helm chart to used to install voltha                                                |
| `VOLTHA_ADAPTER_SIM_CHART`      | onf/voltha-adapter-simulated | Helm chart to use to install simulated device adapter                               |
| `VOLTHA_ADAPTER_OPEN_OLT_CHART` | onf/voltha-adapter-openolt   | Helm chart to use to install OpenOlt adapter                                        |
| `VOLTHA_ADAPTER_OPEN_ONU_CHART` | onf/voltha-adapter-openonu   | Helm chart to use to install OpenOnu adapter                                        |

## Create Kubernetes Cluster
Kind provides a command line control tool to easily create Kubernetes clusters
using just a basic Docker envionrment. The following commands will create
the desired deployment of Kubernetes and then configure your local copy of
`kubectl` to connect to this cluster.
```bash
kind create cluster --name=voltha-$TYPE --config $TYPE-cluster.cfg
export KUBECONFIG="$(kind get kubeconfig-path --name="voltha-$TYPE")"
kubectl cluster-info
```

## Initialize Helm
Helm provide a capabilty to install and manage Kubernetes applications. VOLTHA's
default deployment mechanism utilized Helm. Before Helm can be used to deploy
VOLTHA it must be initialized and the repositories that container the artifacts
required to deploy VOLTHA must be added to Helm.
```bash
# Initialize Helm and add the required chart repositories
helm init
helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo add onf https://charts.opencord.org
helm repo update

# Create and k8s service account so that Helm can create pods
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
```

## Install EtcdOperator
ETCD Operator is a utility that allows applications to create and manage ETCD
key/value clusters as Kubernetes resources. VOLTHA utilizes this utility to
create its key/value store. _NOTE: it is not required that VOLTHA create its
own datastore as VOLTHA can utilize and existing datastore, but for this
example VOLTHA will creates its own datastore_
```bash
helm install -f $TYPE-values.yaml --namespace voltha --name etcd-operator stable/etcd-operator
```

### Wait for operator pods
Before continuing the Kubernetes pods associated with ETCD Operator must be in
the `Running` state.
```bash
kubectl get -n voltha pod
```

Once all the pods are in the `Running` state the output, for a **full**
deployment should be similar to the output below. For a **minimal** deployment
there will only be a single pod, the `etcd-operator-etcd-operator-etcd-operator`
pod.
```bash
NAME                                                              READY     STATUS    RESTARTS   AGE
etcd-operator-etcd-operator-etcd-backup-operator-7897665cfq75w2   1/1       Running   0          2m
etcd-operator-etcd-operator-etcd-operator-7d579799f7-bjdnj        1/1       Running   0          2m
etcd-operator-etcd-operator-etcd-restore-operator-7d77d878wwcn7   1/1       Running   0          2m
```

## It is not just VOLTHA
To demonstrate the capability of VOLTHA other _partner_ applications are
required, such as ONOS. The followins sections describe how to install and
configure these _partner_ applications.

_NOTE: It is important to start ONOS before VOLTHA as if they are started in
the reverse order ofagent sometimes does not connect to the SDN controller
[VOL-1764](https://jira.opencord.org/browse/VOL-1764)_.

### ONOS (OpenFlow Controller)
VOLTHA exposes an OLT and its connected ONUs as an OpenFlow switch. To control
that virtual OpenFlow switch an OpenFlow controller is required. For most VOLTHA
deployments that controller is ONOS with a set of ONOS applications installed.
To install ONOS use the following Helm command:
```bash
helm install -f $TYPE-values.yaml --name onos onf/onos
```

#### Exposing ONOS Services
```bash
screen -dmS onos-ui kubectl port-forward service/onos-ui 8181:8181
screen -dmS onos-ssh kubectl port-forward service/onos-ssh 8101:8101
```

#### Configuring ONOS Applications
Configuration files have been provided to configure aspects of the ONOS deployment. The following
curl commands push those configurations to the ONOS instance. It is possible (likely) that ONOS
won't be immediately ready to accept REST requests, so the first `curl` command may need retried
until ONOS is ready to accept REST connections.
```bash
curl --fail -sSL --user karaf:karaf \
	-X POST -H Content-Type:application/json \
	http://127.0.0.1:8181/onos/v1/network/configuration/apps/org.opencord.kafka \
	--data @onos-files/onos-kafka.json
curl --fail -sSL --user karaf:karaf \
	-X POST -H Content-Type:application/json \
	http://127.0.0.1:8181/onos/v1/network/configuration/apps/org.opencord.dhcpl2relay \
	--data @onos-files/onos-dhcpl2relay.json
curl --fail -sSL --user karaf:karaf \
	-X POST -H Content-Type:application/json \
	http://127.0.0.1:8181/onos/v1/configuration/org.opencord.olt.impl.Olt \
	--data @onos-files/olt-onos-olt-settings.json
curl --fail -sSL --user karaf:karaf \
	-X POST -H Content-Type:application/json \
	http://127.0.0.1:8181/onos/v1/configuration/org.onosproject.net.flow.impl.FlowRuleManager \
	--data @onos-files/olt-onos-enableExtraneousRules.json
```

#### SADIS Configuration
The ONOS applications leverage the _Subscriber and Device Information Store (SADIS)_ when processing
EAPOL and DHCP packets from VOLTHA controlled devices. In order for VOLTHA to function propperly
SADIS entries must be configured into ONOS.

The repository contains two example SADIS configuration that can be used with ONOS depending if
you using VOLTHA with _tech profile_ support (`onos-files/onos-sadis-no-tp.json`) or without
_tech profile_ support (`onos-files/onos-sadis-tp.json`). Either of these configurations can be
pushed to ONOS using the following command:
```bash
curl --fail -sSL --user karaf:karaf \
	-X POST -H Content-Type:application/json \
	http://127.0.0.1:8181/onos/v1/network/configuration/apps/org.opencord.sadis \
	--data @<selected SADIS configuration file>
```

When using the `voltha up` script, if you specify `WITH_ONOS=yes` and `CONFIG_SADIS=yes`
then the script will deploy a SADIS configuration based on the setting of `WITH_TP`. If
you would like to deploy a custom SADIS configuration then you can place that in the
file `onos-file/onos-sadis.json` and it will be used instead of the default SADIS
configuration files.

## Install VOLTHA Core
VOLTHA has two main _parts_: core and adapters. The **core** provides the main
logic for the VOLTHA application and the **adapters** contain logic to adapter
vendor neutral operations to vendor specific devices.

Before any adapters can be deployed the VOLTHA core must be installed and in
the `Running` state. The following Helm command installs the core components
of VOLTHA based on the desired deployment type.
```bash
helm install -f $TYPE-values.yaml --set use_go=true --set defaults.log_level=WARN \
	--namespace voltha --name voltha onf/voltha
```

During the install of the core VOLTHA components some containers may "crash" or
restart. This is normal as there are dependencies, such as the read/write cores
cannot start until the ETCD cluster is established and so they crash until the
ETCD cluster is operational. Eventually all the containers should be in a
`Running` state as queried by the command:
```bash
kubectl get -n voltha pod
```

The output should be similar to the following with a different number of
`etcd-operator` and `voltha-etcd-cluster` pods depending on the deployment
type.
```bash
NAME                                                         READY     STATUS    RESTARTS   AGE
etcd-operator-etcd-operator-etcd-operator-7d579799f7-xq6f2   1/1       Running   0          19m
ofagent-8ccb7f5fb-hwgfn                                      1/1       Running   0          4m
ro-core-564f5cdcc7-2pch8                                     1/1       Running   0          4m
rw-core1-7fbb878cdd-6npvr                                    1/1       Running   2          4m
rw-core2-7fbb878cdd-k7w9j                                    1/1       Running   3          4m
voltha-api-server-5f7c8b5b77-k6mrg                           2/2       Running   0          4m
voltha-cli-server-5df4c95b7f-kcpdl                           1/1       Running   0          4m
voltha-etcd-cluster-4rsqcvpwr4                               1/1       Running   0          4m
voltha-kafka-0                                               1/1       Running   0          4m
voltha-zookeeper-0                                           1/1       Running   0          4m
```

## Install Adapters
The following commands install both the simulated OLT and ONU adapters as well
as the adapters for an OpenOLT and OpenONU device.
```bash
helm install -f $TYPE-values.yaml -set use_go=true --set defaults.log_level=WARN \
	--namespace voltha --name sim onf/voltha-adapter-simulated
helm install -f $TYPE-values.yaml -set use_go=true --set defaults.log_level=WARN \
	--namespace voltha --name open-olt onf/voltha-adapter-openolt
helm install -f $TYPE-values.yaml -set use_go=true --set defaults.log_level=WARN \
	--namespace voltha --name open-onu onf/voltha-adapter-openonu
```

## Exposing VOLTHA Services
At this point VOLTHA is deployed and from within the Kubernetes cluster the
VOLTHA services can be reached. However, from outside the Kubernetes cluster the
services cannot be reached.
```bash
screen -dmS voltha-api kubectl port-forward -n voltha service/voltha-api 55555:55555
screen -dmS voltha-ssh kubectl port-forward -n voltha service/voltha-cli 5022:5022
```

## Install BBSIM (Broad Band OLT/ONU Simulator)
BBSIM provides a simulation of a BB device. It can be useful for testing.
```bash
helm install -f minimal-values.yaml --namespace voltha --name bbsim onf/bbsim
```

## Install FreeRADIUS Service
```bash
helm install -f minimal-values.yaml --namespace voltha --name radius onf/freeradius
```

## Configure `voltctl` to Connect to VOLTHA
In order for `voltctl` to connect to the VOLTHA instance deplpoyed in the
Kubernetes cluster it must know which IP address and port to use. This
configuration can be persisted to a local config file using the following
commands.
```bash
mkdir -p $HOME/.volt
voltctl -a v2 -s localhost:55555 config > $HOME/.volt/config
```

To test the connectivity you can query the version of the VOLTHA client and
server.
```bash
voltctl version
```

The output should be similar to the following
```bash
Client:
 Version        unknown-version
 Go version:    unknown-goversion
 Vcs reference: unknown-vcsref
 Vcs dirty:     unknown-vcsdirty
 Built:         unknown-buildtime
 OS/Arch:       unknown-os/unknown-arch

Cluster:
 Version        2.1.0-dev
 Go version:    1.12.6
 Vcs feference: 28f120f1f4751284cadccf73f2f559ce838dd0a5
 Vcs dirty:     false
 Built:         2019-06-26T16:58:22Z
 OS/Arch:       linux/amd64
```

## Create and Enable a Simulated device
Once all the containers are up and running, a simulated device to "test" the
system can be created using the following command.
```bash
voltctl device create
```

_NOTE: If the device fails to create and an error message is displayed you may
have hit an existing bug in onos
[VOL-1661](https://jira.opencord.org/browse/VOL-1661) . To work around this, use the
`restart-api.sh` included in the repository. After running this script you will
have to quit and restart the screen sesssion associated with the voltha-api._

The output of the command will be the device ID. All the known devices can be
listed with the following command.
```bash
voltctl device list
```

The output should be similar to the following
```bash
ID                          TYPE             ROOT    PARENTID    SERIALNUMBER    VLAN    ADMINSTATE        OPERSTATUS    CONNECTSTATUS
1d5382581e2198ded3b9bcd8    simulated_olt    true                                0       PREPROVISIONED    UNKNOWN       UNKNOWN
```

To enable a device, specify the the device ID
```bash
voltctl device enable 1d5382581e2198ded3b9bcd8
```

When a device is enabled VOLTHA communicates with the device to discover the
ONUs associated with the devices. Using the device and logicaldevice
sub-commands, `list` and `ports` the information VOLTHA discovered can be
displayed.

```bash
$ voltctl device list
ID                          TYPE             ROOT     PARENTID                    SERIALNUMBER           VLAN    ADMINSTATE    OPERSTATUS    CONNECTSTATUS
1d5382581e2198ded3b9bcd8    simulated_olt    true     4F35373B6528                44.141.111.238:7941    0       ENABLED       ACTIVE        REACHABLE
5660880ea2b602081b8203fd    simulated_onu    false    1d5382581e2198ded3b9bcd8    82.24.38.124:9913      101     ENABLED       ACTIVE        REACHABLE
7ff85b36a13fdf98450b9d13    simulated_onu    false    1d5382581e2198ded3b9bcd8    204.200.47.166:9758    103     ENABLED       ACTIVE        REACHABLE
bda9d3442e4cf93f9a58b1f2    simulated_onu    false    1d5382581e2198ded3b9bcd8    66.130.155.136:1448    100     ENABLED       ACTIVE        REACHABLE
f546b18b101c287601d5a9dd    simulated_onu    false    1d5382581e2198ded3b9bcd8    72.157.213.155:5174    102     ENABLED       ACTIVE        REACHABLE

$ voltctl device ports 1d5382581e2198ded3b9bcd8
PORTNO    LABEL    TYPE            ADMINSTATE    OPERSTATUS    DEVICEID    PEERS
2         nni-2    ETHERNET_NNI    ENABLED       ACTIVE                    []
1         pon-1    PON_OLT         ENABLED       ACTIVE                    [{7ff85b36a13fdf98450b9d13 1} {bda9d3442e4cf93f9a58b1f2 1} {5660880ea2b602081b8203fd 1} {f546b18b101c287601d5a9dd 1}]

$ voltctl logicaldevice list
ID              DATAPATHID          ROOTDEVICEID                SERIALNUMBER           FEATURES.NBUFFERS    FEATURES.NTABLES    FEATURES.CAPABILITIES
4F35373B6528    00004f35373b6528    1d5382581e2198ded3b9bcd8    44.141.111.238:7941    256                  2                   0x0000000f

$ voltctl logicaldevice ports 4F35373B6528
ID         DEVICEID                    DEVICEPORTNO    ROOTPORT    OPENFLOW.PORTNO    OPENFLOW.HWADDR      OPENFLOW.NAME    OPENFLOW.STATE    OPENFLOW.FEATURES.CURRENT    OPENFLOW.BITRATE.CURRENT
nni-2      1d5382581e2198ded3b9bcd8    2               true        2                  4f:35:37:3b:65:28    nni-2            0x00000004        0x00001020                   32
uni-103    7ff85b36a13fdf98450b9d13    103             false       103                0b:23:05:64:46:2b                     0x00000004        0x00001020                   32
uni-100    bda9d3442e4cf93f9a58b1f2    100             false       100                68:05:4a:56:28:5b                     0x00000004        0x00001020                   32
uni-101    5660880ea2b602081b8203fd    101             false       101                21:57:68:39:44:55                     0x00000004        0x00001020                   32
uni-102    f546b18b101c287601d5a9dd    102             false       102                01:02:03:04:05:06                     0x00000004        0x00001020                   32
```

When a device is enabled VOLTHA also presents that devices as a virtual
OpenFlow switch to ONOS. This can be seen in ONOS via the CLI and UI. ONOS, in
turn, pushes flows down to the virual OpenFlow device, which can then be
displayed via the `voltctl` command. Seeing flows in `voltctl` demonstrates that
VOLTHA has successfully presented the OLT/ONUs as an virtual OpenFlow switch to
ONOS and ONOS has been able to enfluence the OLT/ONU configuraton by assigning
flows.

```bash
$ ssh -p 8101 karaf@localhost
Password:
Welcome to Open Network Operating System (ONOS)!
     ____  _  ______  ____
    / __ \/ |/ / __ \/ __/
   / /_/ /    / /_/ /\ \
   \____/_/|_/\____/___/

Documentation: wiki.onosproject.org
Tutorials:     tutorials.onosproject.org
Mailing lists: lists.onosproject.org

Come help out! Find out how at: contribute.onosproject.org

Hit '<tab>' for a list of available commands
and '[cmd] --help' for help on a specific command.
Hit '<ctrl-d>' or type 'system:shutdown' or 'logout' to shutdown ONOS.

onos> devices
id=of:00004f35373b6528, available=true, local-status=connected 6m51s ago, role=MASTER, type=SWITCH, mfr=, hw=simulated_pon, sw=simulated_pon, serial=44.141.111.238:7941, chassis=4f35373b6528, driver=default, channelId=10.244.1.16:56302, managementAddress=10.244.1.16, protocol=OF_13
onos> ^D
onos>
Connection to localhost closed.
```

```bash
$ voltctl device flows 1d5382581e2198ded3b9bcd8
ID                  TABLEID    PRIORITY    COOKIE       INPORT    VLANID    VLANPCP    ETHTYPE    METADATA              TUNNELID    SETVLANID    POPVLAN    PUSHVLANID    OUTPUT
7504ed89e9db100f    0          40000       ~deb05c25    1         103                  0x888e                           103         4000                    0x8100        CONTROLLER
2d0d9951533d886c    0          40000       0            2         4000      0                     0x0000000000000067    103                      yes                      1
fa6b175a31b29ab2    0          40000       ~deb05c25    1         100                  0x888e                           100         4000                    0x8100        CONTROLLER
211e554ad8933810    0          40000       0            2         4000      0                     0x0000000000000064    100                      yes                      1
3c61b06b7140f699    0          40000       ~deb05c25    1         101                  0x888e                           101         4000                    0x8100        CONTROLLER
faf13be01f7220fe    0          40000       0            2         4000      0                     0x0000000000000065    101                      yes                      1
f0002ab45e5d9c0a    0          40000       ~deb05c25    1         102                  0x888e                           102         4000                    0x8100        CONTROLLER
cb6506ce6cd5f815    0          40000       0            2         4000      0                     0x0000000000000066    102                      yes                      1
1ba03e16bcc071eb    0          40000       ~2ab3e948    1         103                  0x0806                           103         4000                    0x8100        2
18d6c34108732730    0          40000       ~2ab3e948    1         100                  0x0806                           100         4000                    0x8100        2
c6a21ac1bc742efd    0          40000       ~2ab3e948    1         101                  0x0806                           101         4000                    0x8100        2
a8346901fe5c6547    0          40000       ~2ab3e948    1         102                  0x0806                           102         4000                    0x8100        2

$ voltctl logicaldevice flows 4F35373B6528
ID                  TABLEID    PRIORITY    COOKIE       ETHTYPE    OUTPUT        CLEARACTIONS
85df95ba0c6fbff3    0          40000       ~2ab3e948    0x0806     CONTROLLER    []
dd6707b7a6ff74cf    0          40000       ~deb05c25    0x888e     CONTROLLER    []
```

## Teardown
To remove the cluster simply use the `kind` command:
```bash
kind delete cluster --name=voltha-$TYPE
```

## Troubleshooting
There exists a bug in VOLTHA (as of 8/14/2019) where the API server doesn't always
correctly connect to the back end services. To work around this bug, the `voltha-api-server`
and `ofagent` can be restarted as described below.
```bash
kubectl scale --replicas=0 deployment -n voltha voltha-api-server ofagent
```

Wait for the POD to be removed, then scale it back up.
```bash
kubectl scale --replicas=1 deployment -n voltha voltha-api-server ofagent
```

## WIP

### Create BBSIM Device


#### Create BBSIM Device
```bash
voltctl device create -t openolt -H $(kubectl get -n voltha service/bbsim -o go-template='{{.spec.clusterIP}}'):50060
```

#### Enable BBSIM Device
```bash
voltctl device enable $(voltctl device list --filter Type~openolt -q)
```
