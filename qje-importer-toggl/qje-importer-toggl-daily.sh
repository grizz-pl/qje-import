#!/bin/bash
# qje-importer-toggl-daily.sh
# by Witold Firlej (grizz) https://grizz.pl https://github.com/grizz-pl
# Get daily summary and details from Toggl as a markdown file with tables.
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
    RAPORT_DATE=$(date -d "$date -1 days" +"%Y-%m-%d") #yesterday
    echo "Toggl for YESTERDAY - $RAPORT_DATE"
else
    if date -d "$1" &>/dev/null; then
        RAPORT_DATE=$1
    else
        echo "$1 is not a valid YYYY-MM-DD date"
        exit 1
    fi

    echo "Toggl for $RAPORT_DATE"
fi

cd $WORKING_DIR
TARGET_FILE=$(date -d "$RAPORT_DATE" +"$TARGET_FILE_DAILY_FORMAT")

# sumary

curl -s 'https://track.toggl.com/reports/api/v3/workspace/'$TOGGL_WORKSPACE'/summary/time_entries.csv' \
    -H 'authorization: Basic '$API3_TOKEN'' \
    -H 'content-type: application/json' \
    -H 'accept: */*' \
    -H 'origin: https://track.toggl.com' \
    -H 'sec-fetch-site: same-origin' \
    --data-raw '{"start_date":"'$RAPORT_DATE'","end_date":"'$RAPORT_DATE'","order_by":"title","order_dir":"asc","grouping":"projects","sub_grouping":"time_entries","duration_format":"improved","date_format":"DD.MM.YYYY","hide_amounts":true,"hide_rates":true}' >tmps

#details

curl -s -u $API2_TOKEN:api_token -X GET "https://api.track.toggl.com/reports/api/v2/details.csv?workspace_id=$TOGGL_WORKSPACE&since=$RAPORT_DATE&until=$RAPORT_DATE&user_agent=api_test&grouping=projects&subgrouping=time_entries&order_field=duration&order_desc=on" >tmpd

# make temp with all data
if [ $ADD_DENDRON_FRONTMATTER == "true" ]; then
    echo "---" >tmpw                          # frontmater for Dendron
    echo "title: Toggl - $RAPORT_DATE" >>tmpw # frontmater for Dendron
    echo "---" >>tmpw                         # frontmater for Dendron
    echo >>tmpw
else
    echo >tmpw
fi
echo
echo "# Toggl - $RAPORT_DATE" >>tmpw
echo >>tmpw
echo "## Summary" >>tmpw
echo >>tmpw
cat tmps |
    sed -e "s/,/ \| /g" | #  make table from commas
    sed -e "s/Duration\$/Duration\n\-------\|---------\|-------------\|----------\|/g" \
        >>tmpw # add header line
echo >>tmpw
echo "## Details" >>tmpw
echo >>tmpw
cat tmpd |
    cut -d, -f3-4,6,8-12 |     # get interesting columns - remove this line to get all cols
    sed -e "s/,/ \| /g" |      # make table from commas
    sed -e "s/^\ | /-- \|/g" | # replace empty client with --
    sed -e "s/Duration\$/Duration\n$(printf '%.0s-----\|' {1..8})/g" \
        >>tmpw #add header line - the n number in {1..n} should correspond to the number of columns
echo >>tmpw

#display outfile
# cat tmpw

#save to target file

echo "saving to" $TARGET_FILE
if test -f "$TARGET_FILE"; then
    echo "$TARGET_FILE exists. Aborting saving. Data is in tmpw file."
else
    cat tmpw >$TARGET_FILE
    echo "Daily file saved! Bye!"
fi
