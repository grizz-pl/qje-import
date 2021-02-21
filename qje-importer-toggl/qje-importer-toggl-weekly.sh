#!/bin/bash
# qje-importer-toggl-weekly.sh
# by Witold Firlej (grizz) https://grizz.pl https://github.com/grizz-pl
# Get weekly summary from Toggl as a markdown file with tables.
# version 0.2.0
# 2021-02-21
# gpl-3.0 LICENSE
#
# PLEASE read readme.md and comments below
#

### configuration
if test -f "qje-importer-toggl-config.sh"; then
    source qje-importer-toggl-config.sh
else
    echo "There is no configuration file qje-importer-toggl-config.sh. Quit."
    exit 1
fi

###

echo ""

if [ "$#" -eq "0" ]; then
    REPORT_DATE=$(date -d "$date -1 days" +"%Y-%m-%d") #yesterday
    echo "Toggl for YESTERDAY - $REPORT_DATE"
else
    if date -d "$1" &>/dev/null; then
        REPORT_DATE=$1
    else
        echo "$1 is not a valid YYYY-MM-DD date"
        exit 1
    fi

fi

cd $WORKING_DIR
TARGET_FILE=$(date -d "$REPORT_DATE" +"$TARGET_FILE_WEEKLY_FORMAT")
TARGET_FILE_WEEKLY=$(date -d "$REPORT_DATE" +"$TARGET_FILE_WEEKLY_FORMAT")

# weekly summary

if [ $(date -d "$REPORT_DATE" "+%u") -eq $LAST_WEEKDAY ]; then #check if it's sunday
    START_DATE=$(date -d "$REPORT_DATE -6 days" +"%Y-%m-%d")
    END_DATE=$(date -d "$REPORT_DATE" +"%Y-%m-%d")

    echo "Toggl - weekly summary - week $(date -d "$REPORT_DATE" "+%V") - $START_DATE - $END_DATE"

    curl -s 'https://track.toggl.com/reports/api/v3/workspace/'$TOGGL_WORKSPACE'/summary/time_entries.csv' \
        -H 'authorization: Basic '$API3_TOKEN'' \
        -H 'content-type: application/json' \
        -H 'accept: */*' \
        -H 'origin: https://track.toggl.com' \
        -H 'sec-fetch-site: same-origin' \
        --data-raw '{"start_date":"'$START_DATE'","end_date":"'$END_DATE'","order_by":"duration","order_dir":"desc","grouping":"users","sub_grouping":"clients","duration_format":"improved","date_format":"DD.MM.YYYY","hide_amounts":true,"hide_rates":true}' >tmps

    echo "" >>tmps

    curl -s 'https://track.toggl.com/reports/api/v3/workspace/'$TOGGL_WORKSPACE'/summary/time_entries.csv' \
        -H 'authorization: Basic '$API3_TOKEN'' \
        -H 'content-type: application/json' \
        -H 'accept: */*' \
        -H 'origin: https://track.toggl.com' \
        -H 'sec-fetch-site: same-origin' \
        --data-raw '{"start_date":"'$START_DATE'","end_date":"'$END_DATE'","order_by":"duration","order_dir":"desc","grouping":"clients","sub_grouping":"projects","duration_format":"improved","date_format":"DD.MM.YYYY","hide_amounts":true,"hide_rates":true}' >>tmps

    echo "" >>tmps

    curl -s 'https://track.toggl.com/reports/api/v3/workspace/'$TOGGL_WORKSPACE'/summary/time_entries.csv' \
        -H 'authorization: Basic '$API3_TOKEN'' \
        -H 'content-type: application/json' \
        -H 'accept: */*' \
        -H 'origin: https://track.toggl.com' \
        -H 'sec-fetch-site: same-origin' \
        --data-raw '{"start_date":"'$START_DATE'","end_date":"'$END_DATE'","order_by":"duration","order_dir":"desc","grouping":"projects","sub_grouping":"time_entries","duration_format":"improved","date_format":"DD.MM.YYYY","hide_amounts":true,"hide_rates":true}' >>tmps

    # make temp with all data
    echo "---" >tmpw                                                                                             # frontmater for Dendron
    echo "title: Toggl - weekly summary - week $(date -d "$REPORT_DATE" "+%V") - $START_DATE - $END_DATE" >>tmpw # frontmater for Dendron
    echo "---" >>tmpw                                                                                            # frontmater for Dendron
    echo >>tmpw
    echo "# Toggl - week $(date -d "$REPORT_DATE" "+%V") - $START_DATE - $END_DATE" >>tmpw
    echo >>tmpw
    echo "## Summary" >>tmpw
    echo >>tmpw
    cat tmps |
        sed -e "s/,/ \| /g" |
        sed -e "s/Duration\$/Duration\n\-------\|---------\|-------------\|----------\|/g" \
            >>tmpw #  make table from commas, add header line
    echo >>tmpw

    #display outfile
    # cat tmpw

    #save to target file

    echo "saving to" $TARGET_FILE_WEEKLY
    if test -f "$TARGET_FILE_WEEKLY"; then
        echo "$TARGET_FILE_WEEKLY exists. Aborting saving. Data is in tmpw file."
    else
        cat tmpw >$TARGET_FILE_WEEKLY
        echo "Weekly file saved! Bye!"
    fi

else
    echo "Aborting. $REPORT_DATE is not the $LAST_WEEKDAY of a week"
fi
