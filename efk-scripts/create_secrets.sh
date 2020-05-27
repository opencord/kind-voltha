#!/bin/bash

## Create secrets for elasticsearch and kibana.Secrets can be used by elasticsearch to create new user and templates.Kibana and fluentd use these secrets to login to elasticsearch
encryptionkey=$(docker run --rm busybox:1.31.1 /bin/sh -c "< /dev/urandom tr -dc _A-Za-z0-9 | head -c50")
kubectl create secret generic kibana --from-literal=encryptionkey=$encryptionkey -n voltha
kubectl create secret generic elastic-credentials --from-literal=password=changeme --from-literal=username=elastic -n voltha
kubectl create secret generic elastic-config-credentials --from-literal=password=<password> --from-literal=username=<username> -n voltha
