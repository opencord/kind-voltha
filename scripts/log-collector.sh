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

# This script periodically collects the POD logs and puts them bin a "RAW"
# location to be procssed into rolling log files

RAW_LOG_DIR=${RAW_LOG_DIR:-./logger/raw}
PERIOD=${PERIOOD:-15}

# === END OF CONFIGURATION ===
set -o pipefail

# Ensure raw log area exists
mkdir -p $RAW_LOG_DIR
SINCE=

# forever
while true; do
    TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    SINCE_FLAG=
    SINCE_MSG=

    # On iteraton 2+ we use the --since-time option to minimize the size of 
    # the logs collected as well as minimize the overlap with previous
    # collection iteration
    if [ ! -z "$SINCE" ]; then
        SINCE_FLAG="--since-time=$SINCE"
        SINCE_MSG="since $SINCE "
    fi

    # Build up the logs in a temp directory and then move that to the 
    # RAW area when complete
    WORK=$(mktemp -d)

    # All VOLTHA PODS + ONOS
    PODS="$(kubectl -n default get pod -o name | grep onos | sed -e 's/^/default:/g') $(kubectl get -n voltha pod -o name | sed -e 's/^/voltha:/g')"
    if [ $? -ne 0 ]; then
        echo "Failed to get PODs from Kubernetes, will retry after sleep ..."
    else
        echo "Dumping POD logs at $TS $SINCE_MSG..."
        for POD in $PODS; do
            NS=$(echo $POD | cut -d: -f1)
            POD=$(echo $POD | cut -d: -f2 | sed -e 's/^pod\///g')
            echo "    $POD"
            kubectl logs --timestamps=true $SINCE_FLAG -n $NS --all-containers $LOG_ARGS $POD 2>/dev/null > $WORK/$POD.log
            if [ $? -ne 0 ]; then
                echo "        ERROR: Encountered while getting POD log, removing failed entry"
                rm -f $WORK/$POD.log
            elif [ $(cat $WORK/$POD.log | wc -l) -eq 0 ]; then
                # empty
                rm -f $WORK/$POD.log
            fi
        done
        if [ $(ls -1 $WORK/ | wc -l) -eq 0 ]; then
            # Work directory is empty, no need to move it to raw area, just
            # remove it
            rm -rf $WORK
        else
            mv $WORK $RAW_LOG_DIR/$TS
        fi
    fi

    # End iteration and sleep until next iteration
    echo "====="
    SINCE=$TS
    echo "Sleep for $PERIOD seconds ..."
    sleep $PERIOD
done
