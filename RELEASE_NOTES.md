# April 7, 2020
- Etcd and Kafka can be installed independently of VOLTHA, with `WITH_ETCD` and/or `WITH_KAFKA` set to their endpoints:
  - `WITH_ETCD=y WITH_KAFKA=y` installs Etcd and Kafka in the `voltha` namespace
  - `WITH_ETCD=external WITH_KAFKA=external` installs Etcd and Kafka in the `default` namespace
  - `WITH_ETCD=<etcd-endpoint> WITH_KAFKA=<kafka-endpoint>` connects the deployment to pre-deployed instance of Etcd and Kafka
- `WITH_ETCD`, `WITH_KAFKA`, and `WITH_ONOS` when used to specify external services (i.e. services that are not nessisarily deployed as part of `kind-voltha`) require the format for each of these is `service-name`[`:port`]. Port is optional and will default to the standard port for the given service.
- Separate namespaces can be specified for various components
  - `VOLTHA_NS`  (default: `voltha`)  for cores, ofagent, Etcd (yes), Kafka (yes)
  - `ADAPTER_NS` (default: `voltha`)  for device adapters
  - `INFRA_NS`   (default: `default`) for RADIUS, ONOS, Etcd (external), Kafka (external)
  - `BBSIM_NS`   (default: `voltha`)  for BBSIM instances


The changes in this release enable the ability to shorten the development cycle by allowing developers only to cycle (restart) the components required.

For example, if VOLTHA is started with the following command:
```
WITH_BBSIM=y WITH_RADIUS=y CONFIG_SADIS=y WITH_ONOS=y WITH_ETCD=external WITH_KAFKA=external INFRA_NS=infra BBSIM_NS=devices ADAPTER_NS=adapters ./voltha up
```
And then brought down with the following command:
```
DEPLOY_K8S=n WITH_BBSIM=y WITH_RADIUS=no CONFIG_SADIS=no  WITH_ONOS=no WITH_ETCD=no WITH_KAFKA=no INFRA_NS=infra BBSIM_NS=devices ADAPTER_NS=adapters ./voltha down
```
Then it can be restarted with the following command and only the VOLTHA core components, adapters, and BBSIM are required to be restarted:
```
DEPLOY_K8S=n WITH_BBSIM=y WITH_RADIUS=no CONFIG_SADIS=no  WITH_ONOS=onos-openflow.infra.svc.cluster.local  WITH_ETCD=etcd-cluster-client.infra.svc.cluster.local WITH_KAFKA=kafka.infra.svc.cluster.local  INFRA_NS=infra BBSIM_NS=devices ADAPTER_NS=adapters ./voltha up
```
In the above examples namespaces are specified, but this is not required.

