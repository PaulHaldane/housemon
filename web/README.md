
Based on https://codepen.io/halvas/pen/GdzeME
with tweaks to accomodate the structure of the data points that I'm pushing to dweet.io.

The dweets from my temperature monitoring system are pushed to dweet.io asynchronously.
That's why I send a timestamp field (in seconds since Unix epoch) rather than relying on
"created". The ts field holds the time that the data point was measured which may be 
some time (up to twenty minutes in normal operation, longer if there are connectivity issues)
before it is sent to dweet.io. 

