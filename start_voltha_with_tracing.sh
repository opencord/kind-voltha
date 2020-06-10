#!/bin/bash

if [ $# -eq 0 ] ; then
  echo "Usage: $0 command"
  exit 1
fi

WITH_TRACING=yes VOLTHA_TRACING_CHART=../voltha-helm-charts/voltha-tracing VOLTHA_CHART=../voltha-helm-charts/voltha VOLTHA_ADAPTER_OPEN_OLT_CHART=../voltha-helm-charts/voltha-adapter-openolt TRACING_GUI_PORT=30686 ./voltha $*
