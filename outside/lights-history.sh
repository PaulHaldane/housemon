#!/bin/sh

sensor_name=new_new_emote_2763

start_time=$(date -v-24H "+%Y%m%d%H%M%S")
end_time=$(date "+%Y%m%d%H%M%S")

url="https://api.newcastle.urbanobservatory.ac.uk/api/v1/sensor/data/raw.json?sensor_name=${sensor_name}"
url="$url&start_time=${start_time}&end_time=${end_time}"

curl --silent $url

# curl --silent "http://uoweb1.ncl.ac.uk/api/v1/sensor/data/raw.json?sensor_name=${sensor_name}&start_time=20180123120000&end_time=20180123130000&api_key=$api_key"
