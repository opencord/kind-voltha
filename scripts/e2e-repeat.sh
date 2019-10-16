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

# this script repeatedly invokes the e2e system test on a VOLTHA instance

NAME=${NAME:-minimal}
EXIT_ON_FAIL=${EXIT_ON_FAIL:-no}
INCLUDE_LOG_DIR=${INCLUDE_LOG_DIR:-}
BBSIM_ONU_SN=${BBSIM_ONIU_SN:-BBSM00000001}
BBSIM_OLT_SN=${BBSIM_OLT_SN:-BBSIM_OLT_0}

# === END OF CONFIGURATION ===

set -o pipefail

if [ ! -r voltha-system-tests ]; then
    git clone http://gerrit.opencord.org/voltha-system-tests voltha-system-tests
fi

delta() {
    local LEFT=$(echo $1 | numfmt --from=iec)
    local RIGHT=$(echo $2 | numfmt --from=iec)
    local V=$(expr $LEFT - $RIGHT)
    echo ${V#-}
}

average() {
    local MIN=0
    local MAX=0
    local COUNT=0
    local SUM=0
    for V in $*; do
        COUNT=$(expr $COUNT + 1)
        SUM=$(expr $SUM + $V)
        if [ $COUNT -eq 1 ]; then
            MIN=$V
            MAX=$V
        else
            if [ $V -lt $MIN ]; then
                MIN=$V
            elif [ $V -gt $MAX ]; then
                MAX=$V
            fi
        fi
    done
    if [ $COUNT -gt 3 ]; then
        SUM=$(expr $SUM - $MIN - $MAX)
        COUNT=$(expr $COUNT - 2)
    fi
    if [ $COUNT -lt 1 ]; then
        echo 0
    else
        echo $(expr $SUM / $COUNT)
    fi
}

export WAIT_FOR_DOWN=y
export TERM=

COMPLETED=0
COUNT_OK=0
COUNT_FAIL=0
COUNT_SINCE_FAIL=0
FAILURE_LIST=()
RSS_DIFFS=()
KEY_DIFFS=()
SIZE_DIFFS=()
LOG=$(mktemp)
FIRST=1
while true; do 
  RUN_TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  echo "START RUN $RUN @ $RUN_TS" | tee -a $LOG
  if [ $FIRST -eq 1 ]; then
      DEPLOY_K8S=y WITH_BBSIM=y WITH_SADIS=y WITH_RADIUS=y CONFIG_SADIS=y ./voltha up
      FIRST=0
  else
      helm install --wait -f full-values.yaml --set defaults.log_level=WARN --namespace voltha --name bbsim onf/bbsim
  fi
  # because BBSIM needs time
  sleep 60
  ETCD=$(kubectl -n voltha get pods | grep etcd-cluster | awk '{print $1}' | head -1)
  BEFORE_KEY_COUNT=$(kubectl -n voltha exec -ti $ETCD \
      -- sh -c 'ETCDCTL_API=3 etcdctl get --command-timeout=60s --from-key=true --keys-only . | sed -e "/^$/d" | wc -l | tr -d "\r\n"')
  BEFORE_SIZE=$(numfmt --to=iec \
            $(kubectl -n voltha exec -ti $ETCD \
            -- sh -c 'ETCDCTL_API=3 etcdctl endpoint status -w json' | tr -d '\r\n' | jq .[].Status.dbSize))
  BEFORE_RSS=$(ps -eo rss,pid,cmd | grep /usr/local/bin/etcd | grep -v grep | cut -d\  -f1 | numfmt --to=iec)
  (cd voltha-system-tests; BBSIM_OLT_SN=$BBSIM_OLT_SN BBSIM_ONU_SN=$BBSIM_ONU_SN make sanity-kind 2>&1 | tee $LOG)
  FAIL=$?
  AFTER_KEY_COUNT=$(kubectl -n voltha exec -ti $ETCD \
      -- sh -c 'ETCDCTL_API=3 etcdctl get --command-timeout=60s --from-key=true --keys-only . | sed -e "/^$/d" | wc -l | tr -d "\r\n"')
  AFTER_SIZE=$(numfmt --to=iec \
            $(kubectl -n voltha exec -ti $ETCD \
            -- sh -c 'ETCDCTL_API=3 etcdctl endpoint status -w json' | tr -d '\r\n' | jq .[].Status.dbSize))
  AFTER_RSS=$(ps -eo rss,pid,cmd | grep /usr/local/bin/etcd | grep -v grep | cut -d\  -f1 | numfmt --to=iec)
  if [ $FAIL -eq 0 ]; then
      COUNT_OK=$(expr $COUNT_OK + 1)
      COUNT_SINCE_FAIL=$(expr $COUNT_SINCE_FAIL + 1)
      helm delete --purge bbsim
      while [ $(kubectl get --all-namespaces pods,svc 2>&1 | grep -c bbsim) -gt 0 ]; do
          sleep 3
      done
  else
      COUNT_FAIL=$(expr $COUNT_FAIL + 1)
      FAILURE_LIST+=($COUNT_SINCE_FAIL)
      COUNT_SINCE_FAIL=0
      DUMP_FROM=$RUN_TS ./voltha dump
      C_TS=$(echo $RUN_TS | sed -e 's/[:-]//g')

      if [ ! -z "$INCLUDE_LOG_DIR" ]; then
          # Now that we have the dump compressed tar file, expand it into a temp
          # area, augment it with the extended (combined) log files and then
          # repackage it
          WORK=$(mktemp -d)
          tar -C $WORK -zxf voltha-debug-dump-$NAME-$C_TS.tgz
          mkdir $WORK/voltha-debug-dump-$NAME-$C_TS/logs
          for LOG in $(ls -1 $INCLUDE_LOG_DIR/*.log.[0-9]*); do
              LOG_NAME=$(basename $LOG)
              WORK_LOG=$(mktemp)
              cat $LOG | awk "{if ( \$1 >= \"$RUN_TS\" ) print}" > $WORK_LOG
              if [ $(stat -c %s $WORK_LOG) -eq 0 ]; then
                  rm -f $WORK_LOG
              else
                  mv $WORK_LOG $WORK/voltha-debug-dump-$NAME-$C_TS/logs/$LOG_NAME
              fi
          done

          tar -C $WORK -czf voltha-debug-dump-$NAME-$C_TS.tgz ./voltha-debug-dump-$NAME-$C_TS
      fi

      if [ "$EXIT_ON_FAIL" == "yes" ]; then
          exit
      fi

      DEPLOY_K8S=n ./voltha down
  fi
  echo "END RUN: $RUN @ $(date -u +%Y-%m-%dT%H:%M:%SZ)" | tee -a $LOG
  COMPLETED=$(expr $COMPLETED + 1)
  MTBF=0
  if [ ${#FAILURE_LIST[@]} -gt 0 ]; then
      for V in ${FAILURE_LIST[@]}; do
          MTBF=$(expr $MTBF + $V)
      done
      MTBF=$(expr $MTBF \/ ${#FAILURE_LIST[@]})
  fi
  
  RSS_DIFFS+=($(delta $AFTER_RSS $BEFORE_RSS))
  KEY_DIFFS+=($(delta $AFTER_KEY_COUNT $BEFORE_KEY_COUNT))
  SIZE_DIFFS+=($(delta $AFTER_SIZE $BEFORE_SIZE))

  echo "{" | tee -a $LOG
  echo "    NumberOfRuns:  $COMPLETED," | tee -a $LOG
  echo "    Success:       $COUNT_OK," | tee -a $LOG
  echo "    Failed:        $COUNT_FAIL," | tee -a $LOG
  echo "    SinceLastFail: $COUNT_SINCE_FAIL," | tee -a $LOG
  echo "    MTBF:          $MTBF," | tee -a $LOG
  echo "    FAILURES:      ${FAILURE_LIST[@]}," | tee -a $LOG
  echo "    ETCd: {" | tee -a $LOG
  echo "        KeyCount: {" | tee -a $LOG
  echo "            Before: $BEFORE_KEY_COUNT," | tee -a $LOG
  echo "            After:  $AFTER_KEY_COUNT," | tee -a $LOG
  echo "            Average: $(average ${KEY_DIFFS[@]})," | tee -a $LOG
  echo "        }," | tee -a $LOG
  echo "        DbSize: {" | tee -a $LOG
  echo "            Before: $BEFORE_SIZE," | tee -a $LOG
  echo "            After: $AFTER_SIZE," | tee -a $LOG
  echo "            Average: $(numfmt --to=iec $(average ${SIZE_DIFFS[@]}))," | tee -a $LOG
  echo "        }" | tee -a $LOG
  echo "        RSS: {" | tee -a $LOG
  echo "            Before: $BEFORE_RSS," | tee -a $LOG
  echo "            After: $AFTER_RSS," | tee -a $LOG
  echo "            Average: $(numfmt --to=iec $(average ${RSS_DIFFS[@]}))," | tee -a $LOG
  echo "        }" | tee -a $LOG
  echo "    }" | tee -a $LOG
  echo "}" | tee -a $LOG
  if [ $FAIL -ne 0 ]; then
      mkdir -p failures
      cp $LOG failures/$(date -u +"%Y%m%dT%H%M%SZ")-fail-output.log
  fi
done
