#  VOLTHA DEPLOYMENT TOOL
Thie repository describes how to the the `voltha` script to install a 
VOLTHA deployment. `voltha` can be used to deploy an instance into an existing
Kubernetes cluster (physical or virtual) or can be start up a local
docker-in-docker KinD Kuberentes cluster in which to deploy VOLTHA.

When deploying VOLTHA there are several configuration options tha can be
set as described in the [*CONFIGURATION*](#configuration) section below. All configuration
options are specified as envirment variables.

## PREREQUISITES
The `voltha` script uses several standard Linux tools to deploy VOLTHA
including `curl`, `sed`, and `jq`. This tools must be installed before
using the script. The script checks for the presence of these tools before
it deployes VOLTHA and will exit with an error if the tools are not present.

_NOTE: If you are deploying a KinD Kubernetes cluster using the `voltha` 
script, you must also also have Docker installed_

## INSTALL TYPE
The `voltha` script can install two variations or types of a VOLTHA deployment:
**minimal** or **full**. The difference is characterized in the following
table:

| RESOURCE                | MINIMAL       | FULL |
| ----------------------- | ------------- | ------------------------- |
| K8s Control Plane Nodes | 1             | 1 |
| K8s Workers             | 2             | 3 |
| EtcdOperator Components | Operator only | Operator, Backup, Restore |
| EtcdCluster             | 1 Member      | 3 Members |

Throughout this `README.md` file deployment and configuration files are
referenced in the form **$TYPE-cluster.cfg** and **$TYPE-values.yaml**.
Depending on which type of deloyment you wish to install replace **$TYPE**
with either **minimal** or **full**. If you set the environment variable `TYPE`
to the desired deployment type, example below, then the commands can be
executed via a simply copy and paste to your command line.
```bash
export TYPE=minimal
```

## TL;DR
OK, if you really don't care how it starts and you just want it started. After
cloning the repository and making sure you have the prerequisites installed,
just execute 
```bash
DEPLOY_K8S=y WITH_BBSIM=y WITH_RADIUS=y CONFIG_SADIS=y  ./voltha up
```
and the minimal cluster should start.

To remove voltha use `DEPLOY_K8S=y ./voltha down`

## RUN WITHOUT CLONING REPOSITORY
The `voltha` script can be run without cloning the complete repository. To do
so, download the script and run it.
```bash
curl -sSL https://raw.githubusercontent.com/ciena/kind-voltha/master/voltha --output ./voltha
chmod +x ./voltha
DEPLOY_K8S=y WITH_BBSIM=y WITH_RADIUS=y CONFIG_SADIS=y  ./voltha up
```

![Demo @ Speed](./resources/kind-voltha.gif "Demo @ Speed")
_NOTE: Shown significantly sped up (20x), actual install was about 8 minutes._

## CONFIGURATION
The option should be set using environment variables, thus to start VOLTHA
with the BBSIM POD, RADIUS, and ONOS SADIS configured  you could use the
following command:
```bash
WITH_BBSIM=yes WITH_RADIUS=y CONFIG_SADIS=y  voltha up
```

To start a specific version of VOLTHA, e.g. 2.2, you could use the following command:
```bash
source releases/voltha-2.2 && voltha up
```
Please check the `releases` folder to see the available ones.

| OPTION                                | DEFAULT                                               | DESCRIPTION |
| ------------------------------------- | ----------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `TYPE`                                  | minimal                                               | `minimal` or `full` and determines number of cluster nodes and etcd cluster members |
| `NAME`                                  | TYPE                                                  | Name of the KinD Cluster to be created |
| `DEPLOY_K8S`                            | yes                                                   | Should the KinD Kubernetes cluster be deployed? |
| `JUST_K8S`                              | no                                                    | Should just the KinD Kubernetes cluster be depoyed? (i.e. no VOLTHA) |
| `WITH_BBSIM`                            | no                                                    | Should the BBSIM POD be deployed? |
| `NUM_OF_BBSIM`                          | 1                                                     | number of BBSIM POD to start (minimum = 1, maximum = 10) |
| `WITH_ONOS`                             | yes                                                   | Should `ONOS` service be deployed? |
| `WITH_KAFKA`                            | yes                                                   | Deploy private Kafka (yes/no) or k8s servce:port of external Kafka |
| `WITH_ETCD`                             | yes                                                   | Deploy private etcd (yes/no) or k8s service:port of external etcd |
| `WITH_RADIUS`                           | no                                                    | Deploy sample RADIUS server (yes/no) or a k8s service:port of external RADIUS |
| `WITH_EAPOL`                            | no                                                    | Configure the OLT app to push EAPOL flows |
| `WITH_DHCP`                             | no                                                    | Configure the OLT app to push DCHP flows |
| `WITH_IGMP`                             | no                                                    | Configure the OLT app to push IGMP flows |
| `WITH_TIMINGS`                          | no                                                    | Outputs duration of various steps of the install |
| `WITH_CHAOS`                            | no                                                    | Starts kube-monkey to introduce chaos |
| `WITH_ADAPTERS`                         | yes                                                   | Should device adpters be installed, if no overrides options for specific adapters |
| `WITH_SIM_ADAPTERS`                     | no                                                    | Should simulated device adapters be deployed (simulated adpaters deprecated) |
| `WITH_OPEN_ADAPTERS`                    | yes                                                   | Should open OLT and ONU adapters be deployed |
| `WITH_PORT_FORWARDS`                    | yes                                                   | Forwards ports for some services from localhost into the K8s cluster |
| `CONFIG_SADIS`                          | no                                                    | Configure SADIS entries into ONOS. Values: `yes`, `no`, `file`, `url`, or `bbsim` |
| `SADIS_SUBSCRIBERS`                     | http://bbsim.voltha.svc:50074/v2/subscribers/%s       | URL for ONOS to use to query subsriber information if `CONFIG_SADIS` is set to `url` |
| `SADIS_BANDWIDTH_PROFILES`              | http://bbsim.voltha.svc:50074/v2/bandwidthprofiles/%s | URL for ONOS to use to query bandwidth profiles if `CONFIG_SADIS` is set to `url` |
| `SADIS_CFG`                             | onos-files/onos-sadis-sample.json                     | SADIS Configuration File to push, if CONFIG_SADIS set |
| `INSTALL_ONOS_APPS`                     | no                                                    | Replaces/installs ONOS OAR files in onos-files/onos-apps |
| `INSTALL_KUBECTL`                       | yes                                                   | Should a copy of `kubectl` be installed locally? |
| `INSTALL_HELM`                          | yes                                                   | Should a copy of `helm` be installed locallly? |
| `VOLTHA_LOG_LEVEL`                      | WARN                                                  | Log level to set for VOLTHA core processes |
| `ONOS_CHART`                            | onf/voltha                                            | Helm chart to used to install ONOS |
| `ONOS_CHART_VERSION`                    | latest                                                | Version of helm chart for ONOS |
| `VOLTHA_CHART`                          | onf/voltha                                            | Helm chart to used to install voltha |
| `VOLTHA_CHART_VERSION`                  | latest                                                | Version of Helm chart to install voltha |
| `VOLTHA_ADAPTER_SIM_CHART`              | onf/voltha-adapter-simulated                          | Helm chart to use to install simulated device adapter |
| `VOLTHA_ADAPTER_SIM_CHART_VERSION`      | latest                                                | Version of Helm chart to install simulated device adapter |
| `VOLTHA_BBSIM_CHART`                    | onf/bbsim                                             | Helm chart to use to install bbsim |
| `VOLTHA_BBSIM_CHART_VERSION`            | latest                                                | Version of Helm chart to install bbim |
| `VOLTHA_ADAPTER_OPEN_OLT_CHART`         | onf/voltha-adapter-openolt                            | Helm chart to use to install OpenOlt adapter |
| `VOLTHA_ADAPTER_OPEN_OLT_CHART_VERSION` | latest                                                | Version of Helm chart to install OpenOlt adapter |
| `VOLTHA_ADAPTER_OPEN_ONU_CHART`         | onf/voltha-adapter-openonu                            | Helm chart to use to install OpenOnu adapter |
| `VOLTHA_ADAPTER_OPEN_ONU_CHART_VERSION` | latest                                                | Version of Helm chart to install OpenOnu adapter |
| `ONLY_ONE`                              | yes                                                   | Run a single `rw-core`, no `api-server`, and no `ssh` CLI |
| `ENABLE_ONOS_EXTRANEOUS_RULES`          | no                                                    | Set ONOS to allows flow rules not set via ONOS |
| `UPDATE_HELM_REPOS`                     | yes                                                   | Update the Helm repository with the latest charts before installing |
| `WAIT_ON_DOWN`                          | yes                                                   | When tearing down the VOLTHA, don't exit script until all containers are stoped |
| `WAIT_TIMEOUT`                          | 30m                                                   | Time to wait before timing out on lengthy operations |
| `KIND_VERSION`                          | v0.5.1                                                | Version of KinD to install if using a KinD cluster |
| `VOLTCTL_VERSION`                       | latest                                                | Version of `voltctl` to install or up/downgrade to and use |
| `ONOS_API_PORT`                         | dynamic                                               | (advanced) Override dynamic port selection for port forward for ONOS API |
| `ONOS_SSH_PORT`                         | dynamic                                               | (advanced) Override dynamic port selection for port forward for ONOS SSH |
| `VOLTHA_API_PORT`                       | dynamic                                               | (advanced) Override dynamic port selection for port forward for VOLTHA API |
| `VOLTHA_SSH_PORT`                       | dynamic                                               | (advanced) Override dynamic port selection for port forward for VOLTHA SSH |
| `VOLTHA_ETCD_PORT`                      | dynamic                                               | (advanced) Override dynamic port selection for port forward for VOLTHA etcd |
| `VOLTHA_KAFKA_PORT`                     | dynamic                                               | (advanced) Override dynamic port selection for port forward for VOLTHA Kafka API |

### `CONFIG_SADIS` Values

| VALUE            | DESCRIPTION |
| ---------------- | --------------- |
| `yes` or `file`  | use the contents of a file to configure SADIS in ONOS. The file used defaults to<br>`onos-files/onos-sadis-sample.json` but can be specified via the `SADIS_CFG`<br>environment variable |
| `no`             | do not configure ONOS for SADIS usage |
| `url`            | configure ONOS to use SADIS via a URL. The URL used for subscriber information<br> is specified in the variable `SADIS_SUBSCRIBERS` and the URL used for bandwidth<br> profiles is specified in the variable `SADIS_BANDWIDTH_PROFILES` |
| `bbsim`          | configure ONOS use use the SADIS servers that are part of BBSIM |


## GENERATED CONFIGURATION
When the voltha script is run it generates a file that contains the
configuration settings. This file will be named `$TYPE-env.sh`. The user can
`source` this file to set the configuration as well as establish key environment
variables in order to access VOLTHA, including:

| VARIABLE   | DESCRIPTION |
| ---------- | ---------------------------------------------------------------------------- |
| KUBECONFIG | Sets the configuration file for the Kubernetes control application `kubectl` |
| VOLTCONFIG | Sets the configuration file for the VOLTHA control application `voltctl` |
| PATH       | Augments the `PATH` to include `kubectl` and `voltctl` |

After `voltha up` is run, it is useful to source this file.

## QUICK CHECK
After source the `$TYPE-env.sh` file, you should be able to access VOLTHA via
the control application `voltctl`. To validate this you can use the following
command
```bash
voltctl version
```
and should see output similar to
```
Client:
 Version        1.0.14
 Go version:    go1.12.8
 Vcs reference: 086629f0403fe67213fa0df5dc4d7b7ee317cbac
 Vcs dirty:     false
 Built:         2020-03-03T13:48:00Z
 OS/Arch:       linux/amd64

Cluster:
 Version        2.3.3-dev
 Go version:    1.13.8
 Vcs feference: aa8bd4dcc3510caf2c5362106d9bff2852663d31
 Vcs dirty:     false
 Built:         2020-03-06T16:16:47Z
 OS/Arch:       linux/amd64
```

## TROUBLESHOOTING
When VOLTHA is installed the install log is written to the file
`install-$TYPE.log`. If the install appears stalled or is not completing
consulting this file may indicate the reason.

Similarly, when VOLTHA is uninstalled `down-$TYPE.log` is written and should
be consulted in the event of an error or unexpected result.
