#!/usr/bin/env bash

WITH_ONOS=yes WITH_BBSIM=yes WITH_ETCD=external WITH_KAFKA=external WITH_RADIUS=yes ADAPTER_NS="$NAME" VOLTHA_NS="$NAME" ./voltha up
