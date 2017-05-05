#!/bin/bash

htpasswd -cb /etc/nginx/.htpasswd $HTTP_USER $HTTP_PASSWD
service nginx start

function run {
    s3cmd sync $S3_LINK /data
    zcat -r /data | goaccess -o /var/www/html/index.html --ignore-crawlers --html-custom-js=custom.js -
}

while true;
do
    run
    sleep $REFRESH_DELAY
done
