
## serial.pl

Perl script to open serial port (which presents interface to Xinorf radio transceiver), 
parses out data packets and writes corresponding mongodb insert statements to output.

## mongodb-insert

Shell script which uses the output file produced by serial.pl and sends data to external
mongodb service (for long term storage) as well as dweet.io (for easy, short term access).

Intended to be run at suitable intervals from cron. Idea is that data is sent by monitors in 
real time, stored temporarily on the local unix machine and then transmitted to external 
data storage as connectivity allows. This script needs better error handling. At the moment
it won't notice if the transfer to mongodb or dweet.io fails and so would lose data.
Perhaps better to use rabbitmq or similar.

Current implementation requires logtail.

The mongodb service at mlab doesn't support connections from 
clients before ~3.2 so you way need to build/acquire a copy of mongo
binary from a newer version that comes with your distro.

There's currently no mechanism (other than restarting serial.pl) to truncate the intermediate
text file.
