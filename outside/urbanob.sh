#!/bin/sh

curl "http://uoweb1.ncl.ac.uk/api/v1/sensors/data/raw.csv?start_time=20150117120000&end_time=20150117130000&sensor_type=Weather&api_key=$api_key"
