#!/bin/bash
DEVICE_ID=$1

BEST_DATE=
BEST_POD=
for POD in $(kubectl -n voltha get pods -l app=rw-core -o 'jsonpath={.items[*].metadata.name}'); do
    FOUND=$(kubectl -n voltha logs $POD | grep $DEVICE_ID | grep -i ownedbyme | tail -1)
    if [ ! -z "$FOUND" ]; then
        OWNED=$(echo $FOUND | grep '"owned":true')
        if [ ! -z "$OWNED" ]; then
            CUR_DATE=$(echo $OWNED | jq -r .ts)
            CUR_POD=$(echo $OWNED | jq -r .instanceId)
            if [ -z "$BEST_POD" ]; then
                BEST_DATE=$CUR_DATE
                BEST_POD=$CUR_POD
            elif [ $CUR_DATE > $BEST_DATE ]; then
                BEST_DATE=$CUR_DATE
                BEST_POD=$CUR_POD
            fi
        fi
    fi
done
echo $BEST_POD
