#!/bin/bash

# Delete secrets created for efk security
kubectl delete secret kibana
kubectl delete secret elastic-credentials
kubectl delete secret elastic-config-credentials
