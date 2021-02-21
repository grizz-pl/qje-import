#!/bin/bash
# Get Toggl daily reports for interval
# qje-importer-toggl-config.sh
# by Witold Firlej (grizz) https://grizz.pl https://github.com/grizz-pl
# Configuration file for qje-importer-toggl-weekly.sh and qje-importer-toggl-weekly.sh
# version 0.2.0
# 2021-02-21
# gpl-3.0 LICENSE
#
# PLEASE read readme.md and comments below
#



if [ "$#" -eq "0" ]; then
    echo "Get Toggl daily reports for interval"
    echo "usage: qje-importer-toggl-mass.sh YYYY-MM-DD YYYY-MM-DD"
    exit 1
else
    if date -d "$1" &>/dev/null; then # TODO: better date format checking
        START_DATE=$1
    else
        echo "$1 is not a valid YYYY-MM-DD date"
        exit 1
    fi

    if date -d "$2" &>/dev/null; then
        END_DATE=$2
    else
        echo "$2 is not a valid YYYY-MM-DD date"
        exit 1
    fi
fi

echo ":::Get Toggl daily reports for $START_DATE - $END_DATE"

until [[ $START_DATE > $END_DATE ]]; do
    bash qje-importer-toggl-daily.sh $START_DATE
    bash qje-importer-toggl-weekly.sh $START_DATE
    START_DATE=$(date -d "$START_DATE +1 days" +"%Y-%m-%d")
    sleep .2 # to do not abuse api
done
