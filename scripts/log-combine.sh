#!/bin/sh
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

# This script reads RAW log data collected from the PODS and combines
# this RAW data into a rolloing log file.

RAW_LOG_DIR=${RAW_LOG_DIR:-./logger/raw}
COMBINED_LOG_DIR=${COMBINED_LOG_DIR:-./logger/combined}
ROLL_AT=${ROLL_AT:-100M}
MAX_LOG_COUNT=${MAX_LOG_COUNT:-5}
PERIOD=${PERIOD:-60}

# === END OF CONFIGURATION ===

# Convert the ROLL_AT value to byes
ROLL_AT=$(numfmt --from=iec $ROLL_AT)

# Ensure the combined directory exists
mkdir -p $COMBINED_LOG_DIR

# Get a working area
WORK=$(mktemp)

# forever ...
while true; do

    # Iterate over all existing raw entries
    for MERGE_DIR in $(ls $RAW_LOG_DIR); do
        echo "Merging from $RAW_LOG_DIR/$MERGE_DIR ..."

        # Iterate over each file in the RAW data directory
        for FILE_PATH in $(ls $RAW_LOG_DIR/$MERGE_DIR/*.log); do

            # Get the base of the log file
            FILE=$(basename $FILE_PATH)

            # Find destination log file with largest index, if none
            # exists this will end up with IDX == 1
            IDX=2
            while [ -f $COMBINED_LOG_DIR/$FILE.$(printf "%04d" $IDX) ]; do
                IDX=$(expr $IDX + 1)
            done
            IDX=$(expr $IDX - 1)

            # Get the NAME of the log file to write
            NAME=$COMBINED_LOG_DIR/$FILE.$(printf "%04d" $IDX)

            # different behavior if the file exists or not
            if [ -f $NAME ]; then

                # if the file exists, check the size of the file and see
                # if we need to move to the next index
                SIZE=$(stat -c %s $NAME)
                if [ $SIZE -gt $ROLL_AT ]; then

                    # Combine the exists log file with the new data, this will
                    # have double entires for the overlap, then run it through
                    # uniq -D | sort -u  to only end up with the overlap entries
                    cat $NAME $FILE_PATH | sort | uniq -D | sort -u > $WORK

                    # time to move
                    IDX=$(expr $IDX + 1)

                    # If the nex IDX is great than the max log file count thebn
                    # we shift each log file to index - 1, losing the first (.1)
                    # forever ... 
                    if [ $IDX -gt $MAX_LOG_COUNT ]; then
                        echo "    Shifting log files for $FILE ..."
                        I=1
                        while [ $I -lt $MAX_LOG_COUNT ]; do
                            rm -f $COMBINED_LOG_DIR/$FILE.$(printf "%04d" $I)
                            mv $COMBINED_LOG_DIR/$FILE.$(printf "%04d" $(expr $I + 1)) $COMBINED_LOG_DIR/$FILE.$(printf "%04d" $I)
                            I=$(expr $I + 1)
                        done

                        # Reset the IDX to the MAX
                        IDX=$MAX_LOG_COUNT
                    fi

                    # 
                    NAME=$COMBINED_LOG_DIR/$FILE.$(printf "%04d" $IDX)
                    echo "    Creating new log file $NAME ..."

                    # Combine the list of overlap entries (WORK), i.e. the ones
                    # that need to be removed from the new data set with the 
                    # new data set so that there will be 2 of each of the overlaps.
                    # then pipe that to uniq -u to return only the uniq entries.
                    # this has the affect of removing the overlap from the new
                    # data set
                    cat $WORK $FILE_PATH | sort | uniq -u > $NAME
                    chmod 644 $NAME
                else
                    # Not rolling so a simple combining of the new data set
                    # with the existing file and sorting to only unique entries
                    # will do
                    cat $NAME $FILE_PATH | sort -u > $WORK
                    rm -f $NAME
                    mv $WORK $NAME
                    chmod 644 $NAME
                fi
            else
                # The destination log file does not exist, so just sort the
                # the RAW data into the file. This really only happens on the
                # first iteration
                sort -u $FILE_PATH > $NAME
                chmod 644 $NAME
            fi
        done

        # Remove the RAW data directory so we don't try to merge it again
        rm -rf $RAW_LOG_DIR/$MERGE_DIR
    done
    echo "====="
    echo "Sleep for $PERIOD seconds ..."
    sleep $PERIOD
done
