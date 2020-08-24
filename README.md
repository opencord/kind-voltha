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

## NAMING YOUR CLUSTER

The `voltha` script can be used to manage multiple clusters at the same time,
thus it's important to always name your cluster.

```bash
export NAME=minimal
```

Throughout this `README.md` file you'll find multiple references to `$NAME`
and that can always be replaced with the name your cluster (the default value is `local`).

## TL;DR
OK, if you really don't care how it starts and you just want it started. After
cloning the repository and making sure you have the prerequisites installed,
just execute
```bash
DEPLOY_K8S=y WITH_BBSIM=y WITH_RADIUS=y CONFIG_SADIS=y ./voltha up
```
and the minimal cluster should start.

To remove voltha use `DEPLOY_K8S=y ./voltha down`

## RUN WITHOUT CLONING REPOSITORY
The `voltha` script can be run without cloning the complete repository. To do
so, download the script and run it.
```bash
curl -sSL https://raw.githubusercontent.com/opencord/kind-voltha/master/voltha --output ./voltha
chmod +x ./voltha
DEPLOY_K8S=y WITH_BBSIM=y WITH_RADIUS=y CONFIG_SADIS=y ./voltha up
```

![Demo @ Speed](./resources/kind-voltha.gif "Demo @ Speed")
_NOTE: Shown significantly sped up (20x), actual install was about 8 minutes._

## CONFIGURATION
The option should be set using environment variables, thus to start VOLTHA
with the BBSIM POD, RADIUS, EFK and ONOS SADIS configured  you could use the
following command:
```bash
WITH_BBSIM=yes WITH_RADIUS=y WITH_EFK=y CONFIG_SADIS=y  voltha up
```

To start a specific version of VOLTHA, e.g. 2.3, you could use the following commands:
```bash
git checkout tags/3.0.3 -b 3.0.3
source releases/voltha-2.3 && voltha up
```
Please check the `releases` folder to see the available ones and pick the correct tag associatet do that release.

| OPTION                                  | DEFAULT                                               | DESCRIPTION |
| --------------------------------------- | ----------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `NAME`                                  | `minimal`                                             | Name of the KinD Cluster to be created |
| `DEPLOY_K8S`                            | yes                                                   | Should the KinD Kubernetes cluster be deployed? |
| `JUST_K8S`                              | no                                                    | Should just the KinD Kubernetes cluster be depoyed? (i.e. no VOLTHA) |
| `SCHEDULE_ON_CONTROL_NODES`             | no                                                    | Untaint the control plane (master) K8s nodes so that PODs may be scheduled on them |
| `VOLTHA_NS`                             | `voltha`                                              | K8s namespace into which to deploy voltha PODs |
| `INFRA_NS`                              | `default`                                             | K8s namespace into which to deploy infrastructure PODs |
| `BBSIM_NS`                              | `voltha`                                              | K8s namespace into which to deploy BBSIM PODs |
| `ADAPTER_NS`                            | `voltha`                                              | K8s namespace into which to deploy VOLTHA adapters |
| `WITH_BBSIM`                            | no                                                    | Should the BBSIM POD be deployed? |
| `WITH_EFK`                              | no                                                    | Should the EFK setup be deployed? |
| `NUM_OF_BBSIM`                          | 1                                                     | number of BBSIM POD to start (minimum = 1, maximum = 10) |
| `NUM_OF_OPENONU`                        | 1                                                     | number of OpenONU POD to start (minimum = 1, maximum = 10) |
| `WITH_ONOS`                             | yes                                                   | Deploy ONOS (yes/no) or service:port of external ONOS |
| `WITH_KAFKA`                            | yes                                                   | Deploy private Kafka (yes/no) or k8s servce:port of external Kafka |
| `WITH_ETCD`                             | yes                                                   | Deploy private etcd (yes/no) or k8s service:port of external etcd |
| `WITH_TRACING`                          | no                                                    | Should Jaeger All-in-one POD be deployed for analysis of Traces? |
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
| `CONFIG_SADIS`                          | no                                                    | Configure SADIS entries into ONOS. Values: `yes`, `no`, `file`, `url`, `bbsim`, or `external` |
| `WITH_PPROF`                            | no                                                    | Forwards ports for Golang pprof webserver in rw-core and openolt-adapter (does not automatically include profiled images) |
| `SADIS_SUBSCRIBERS`                     | http://bbsim0.voltha.svc:50074/v2/subscribers/%s      | URL for ONOS to use to query subsriber information if `CONFIG_SADIS` is set to `url` |
| `SADIS_BANDWIDTH_PROFILES`              | http://bbsim0.voltha.svc:50074/v2/bandwidthprofiles/%s| URL for ONOS to use to query bandwidth profiles if `CONFIG_SADIS` is set to `url` |
| `SADIS_CFG`                             | onos-files/onos-sadis-sample.json                     | SADIS Configuration File to push, if CONFIG_SADIS set |
| `BBSIM_CFG`                             | configs/bbsim-sadis-att.yaml                          | Configuration for BBSim services |
| `INSTALL_ONOS_APPS`                     | no                                                    | Replaces/installs ONOS OAR files in onos-files/onos-apps |
| `INSTALL_KUBECTL`                       | yes                                                   | Should a copy of `kubectl` be installed locally? |
| `INSTALL_HELM`                          | yes                                                   | Should a copy of `helm` be installed locallly? |
| `VOLTHA_LOG_LEVEL`                      | WARN                                                  | Log level to set for VOLTHA core processes |
| `ONOS_CHART`                            | onf/voltha                                            | Helm chart to used to install ONOS |
| `ONOS_CHART_VERSION`                    | latest                                                | Version of helm chart for ONOS |
| `ONOS_CLASSIC_CHART`                    | onos/onos-classic                                     | Helm chart to used to install clustered ONOS |
| `ONOS_CLASSIC_CHART_VERSION`            | latest                                                | Version of helm chart for clustered ONOS |
| `VOLTHA_CHART`                          | onf/voltha                                            | Helm chart to used to install voltha |
| `VOLTHA_CHART_VERSION`                  | latest                                                | Version of Helm chart to install voltha |
| `VOLTHA_ADAPTER_SIM_CHART`              | onf/voltha-adapter-simulated                          | Helm chart to use to install simulated device adapter |
| `VOLTHA_ADAPTER_SIM_CHART_VERSION`      | latest                                                | Version of Helm chart to install simulated device adapter |
| `VOLTHA_BBSIM_CHART`                    | onf/bbsim                                             | Helm chart to use to install bbsim |
| `VOLTHA_BBSIM_CHART_VERSION`            | latest                                                | Version of Helm chart to install bbim |
| `ELSTICSEARCH_CHART`                    | elastic/elasticsearch                                 | Helm chart to use to install elasticsearch |
| `ELASTICSEARCH_CHART_VERSION`           | latest                                                | Version of Helm chart to install elasticsearch |
| `KIBANA_CHART`                          | elastic/kibana                                        | Helm chart to use to install kibana |
| `KIBANA_CHART_VERSION`                  | latest                                                | Version of Helm chart to install kibana |
| `FLUENTD_ELSTICSEARCH_CHART`            | kiwigrid/fluentd-elasticsearch                        | Helm chart to use to install fluentd-elasticsearch |
| `FLUENTD_ELASTICSEARCH_CHART_VERSION`   | latest                                                | Version of Helm chart to install fluentd-elasticsearch |
| `VOLTHA_TRACING_CHART`                  | onf/voltha-tracing                                    | Helm chart to use to install voltha tracing |
| `VOLTHA_TRACING_CHART_VERSION`          | latest                                                | Version of Helm chart to install voltha tracing |
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
| `NUM_OF_ONOS`                           | 1                                                     | Number of ONOS instances in the cluster |
| `NUM_OF_ATOMIX`                         | 0                                                     | Number of atomix nodes for the ONOS cluster |
| `ONOS_API_PORT`                         | dynamic                                               | (advanced) Override dynamic port selection for port forward for ONOS API |
| `ONOS_SSH_PORT`                         | dynamic                                               | (advanced) Override dynamic port selection for port forward for ONOS SSH |
| `VOLTHA_API_PORT`                       | dynamic                                               | (advanced) Override dynamic port selection for port forward for VOLTHA API |
| `VOLTHA_SSH_PORT`                       | dynamic                                               | (advanced) Override dynamic port selection for port forward for VOLTHA SSH |
| `VOLTHA_ETCD_PORT`                      | dynamic                                               | (advanced) Override dynamic port selection for port forward for VOLTHA etcd |
| `VOLTHA_KAFKA_PORT`                     | dynamic                                               | (advanced) Override dynamic port selection for port forward for VOLTHA Kafka API |
| `ELASTICSEARCH_PORT`                    | dynamic                                               | (advanced) Override dynamic port selection for port forward for elasticsearch |
| `KIBANA_PORT`                           | dynamic                                               | (advanced) Override dynamic port selection for port forward for  kibana |

### Managing the cluster(s) size
The `voltha` script supports configuration for cluster of different sizes.
For example you can setup an HA cluster with:

```bash
NUM_OF_WORKER_NODES=3 NUM_OF_ONOS=3 NUM_OF_KAFKA=3 NUM_OF_ETCD=3 NUM_OF_ATOMIX=3 ./voltha up
```
As usual one can add as many other options, for example `CONFIG_SADIS=y`.

### Custom Namespaces

Separate namespaces can be specified for various components
  - `VOLTHA_NS`  (default: `voltha`)  for cores, ofagent, Etcd (yes), Kafka (yes)
  - `ADAPTER_NS` (default: `voltha`)  for device adapters
  - `INFRA_NS`   (default: `default`) for RADIUS, ONOS, Etcd (external), Kafka (external)
  - `BBSIM_NS`   (default: `voltha`)  for BBSIM instances

As an example `BBSIM_NS=devices` deployes BBSim in the `devices` namespace.

### External Kafka, Etcd and ONOS
`WITH_ETCD`,  `WITH_KAFKA` and `WITH_ONOS` can have different values depending on the deployment needs:

| VALUE            | DESCRIPTION |
| ---------------- | --------------- |
| `yes` or `y`     | installs Etcd and Kafka in the `voltha` namespace |
| `external`       | installs Etcd and Kafka in the `default` namespace |
| `<endpoint>`     | connects the deployment to pre-deployed instance of the service |

When specifying the `<endpoint>` of the service the format for each of these is `service-name`[`:port`]. Port is optional and will default to the standard port for the given service. For example, `WITH_KAFA=kafka.infra.svc.cluster.local`

Specifying the endpoint enable to use `./voltha up` incrementally, for example:
```
DEPLOY_K8S=n WITH_BBSIM=y WITH_RADIUS=no CONFIG_SADIS=no  WITH_ONOS=onos-openflow.infra.svc.cluster.local  WITH_ETCD=etcd-cluster-client.infra.svc.cluster.local WITH_KAFKA=kafka.infra.svc.cluster.local  INFRA_NS=infra BBSIM_NS=devices ADAPTER_NS=adapters ./voltha up
```
starts VOLTHA with external ONOS,KAFKA,ETCD in the `infra` namespace.

### `CONFIG_SADIS` Values

| VALUE            | DESCRIPTION |
| ---------------- | --------------- |
| `yes` or `file`  | use the contents of a file to configure SADIS in ONOS. The file used defaults to<br>`onos-files/onos-sadis-sample.json` but can be specified via the `SADIS_CFG`<br>environment variable |
| `no`             | do not configure ONOS for SADIS usage |
| `url`            | configure ONOS to use SADIS via a URL. The URL used for subscriber information<br> is specified in the variable `SADIS_SUBSCRIBERS` and the URL used for bandwidth<br> profiles is specified in the variable `SADIS_BANDWIDTH_PROFILES` |
| `bbsim`          | configure ONOS use use the SADIS servers that are part of BBSIM |
| `external`       | an additional helm chart will be installed (`bbsim-sadis-server`) and ONOS will be configured to use that service for SADIS queries |

### `BBSIM_CFG` Values

`BBSIM_CFG` contains a description of the services that is needed to properly configure BBSim.
Examples are available in the `configs` folder. It can be pointed to any valid BBSim service configuration.

You'll note that the examples contain a `:TAG:` placeholder. That is used by `kind-voltha`
to generate different `C/S_TAG` combinations when deploying multiple instances of BBSim and it's
replaced with an incremental number starting from `900`.

### EFK Configuration for accessing Voltha component logs
If EFK is selected for deployment with VOLTHA, `WITH_EFK=yes`, then a single node elasticsearch and kibana
instance will be deployed and a fluentd-elasticsearch pod will be deployed on each node that allows workloads
to be scheduled.

Additionally a port-forward will be established so that you can access elasticsearch(`9200`) and kibana(`5601`)
from outside the Kubernetes cluster. To access the kibana web interface user the URL `http://localhost:5601`.

_NOTE: By default the security and physical persistance(disk) features are not enabled for elasticsearch and kibana.
The security features can be enabled via X-Pack plugin and Role Based Access Control (RBAC) in Elasticsearch by adding
the required settings in yaml file. To enable security features reference the following links:_
[EFK-Setup-With-Kind-Voltha](https://docs.google.com/document/d/1KF1HhE-PN-VY4JN2bqKmQBrZghFC5HQM_s0mC0slapA/edit#)
[elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/elasticsearch-security.html)
[kibana](https://www.elastic.co/guide/en/elasticsearch/reference/7.7/rest-apis.html)

When running an EFK stack in production there are several maintenance that need to be periodically performed
including indexes triming. When planning to deploy an EFK stack to production you should fully understand
the recommendations as described in the product documenation: https://www.elastic.co/guide/index.html

### Jaeger Tracing Stack for analyzing Voltha Component Traces
If Tracing is selected for deployment with VOLTHA using `WITH_TRACING=yes` option, then a single Jaeger
all-in-one instance will be deployed using Memory as Storage backend for traces sent by Voltha conatiners.

Additionally a port-forward will be established so that you can access Jaeger GUI(`16686`) from outside the
 Kubernetes cluster using URL `http://localhost:16686`.

### Controlling VOLTHA with an ONOS cluster

To provide HA, resilinecy and failover ONOS can be configured in cluster mode.
A 3 node ONOS deployment for example can be achieved via:
```bash
NUM_OF_WORKER_NODES=3 WITH_ONOS=classic NUM_OF_ONOS=3 NUM_OF_ATOMIX=3 ./voltha up
```
Please note the above command deploys a 3 worker nodes for k8s and `WITH_ONOS=classic` that uses the
cluster-enabled [helm chart](https://charts.onosproject.org) for ONOS (version 2.2).
The `NUM_OF_ONOS=3 NUM_OF_ATOMIX=3` flags set the number of Atomix nodes and ONOS nodes.

As usual one can add as many other options, for example `CONFIG_SADIS=y`.

## GENERATED CONFIGURATION
When the voltha script is run it generates a file that contains the
configuration settings. This file will be named `$NAME-env.sh`. The user can
`source` this file to set the configuration as well as establish key environment
variables in order to access VOLTHA, including:

| VARIABLE   | DESCRIPTION |
| ---------- | ---------------------------------------------------------------------------- |
| KUBECONFIG | Sets the configuration file for the Kubernetes control application `kubectl` |
| VOLTCONFIG | Sets the configuration file for the VOLTHA control application `voltctl` |
| PATH       | Augments the `PATH` to include `kubectl` and `voltctl` |

After `voltha up` is run, it is useful to source this file.

## QUICK CHECK
After source the `$NAME-env.sh` file, you should be able to access VOLTHA via
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

If you've run the voltha script with `WITH_BBSIM=y` you can now create a BBSIM OLT with
```bash
voltctl device create -t openolt -H bbsim0.voltha.svc:50060
```

## TROUBLESHOOTING
When VOLTHA is installed the install log is written to the file
`install-$NAME.log`. If the install appears stalled or is not completing
consulting this file may indicate the reason.

Similarly, when VOLTHA is uninstalled `down-$NAME.log` is written and should
be consulted in the event of an error or unexpected result.
