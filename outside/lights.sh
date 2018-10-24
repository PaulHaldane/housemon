#!/bin/sh

sensor_name=new_new_emote_2763

# curl --silent "http://uoweb1.ncl.ac.uk/api/v1/sensor/live.json?sensor_name=${sensor_name}&api_key=$api_key"

curl --silent "https://api.newcastle.urbanobservatory.ac.uk/api/v1/sensor/live.json?sensor_name=${sensor_name}"

# curl --silent "http://uoweb1.ncl.ac.uk/api/v1/sensor/data/raw.json?sensor_name=${sensor_name}&start_time=20180123120000&end_time=20180123130000&api_key=$api_key"
