#!/usr/bin/perl -sw

use Device::SerialPort qw( :PARAM :STAT 0.07 );

my $tty = shift;
$tty = 'ttyAMA0' unless $tty;
my $PortName = '/dev/'.$tty;
my $quiet = 0;
my $lockfile = '/tmp/'.$tty.'.lock';

my $PortObj = new Device::SerialPort ($PortName, $quiet, $lockfile)
       || die "Can't open $PortName: $!\n";

$PortObj->user_msg(ON);
$PortObj->databits(8);
$PortObj->baudrate(9600);
$PortObj->parity("none");
$PortObj->stopbits(1);
$PortObj->handshake("rts");

my $STALL_DEFAULT = 300; # how many intervals to wait for new input
 
my $timeout = $STALL_DEFAULT;
 
$PortObj->read_char_time(0);     # don't wait for each character
$PortObj->read_const_time(1000); # 1 second per unfulfilled "read" call
 
$| = 1;
my $verbose = 1;

my %last;
my $storeInterval = 300;

while ($timeout > 0) {
        my ($count, $saw) = $PortObj->read(255); # will read _up to_ 255 chars
        if ($count > 0) {
		$timeout = $STALL_DEFAULT;	# reset timer
		if ((length($saw) % 12) != 0) {
			print STDERR ">>".$saw."<<\n" if $verbose;
			next;
		}
		my $twelve = substr($saw, 0, 12);
		$index = 0;
		while (length($twelve) > 0) {
			unless ($twelve =~ /^a(..)(.*)/) {
				print STDERR ">>".$twelve."<<\n" if $verbose;
				next;
			}
			my ($station, $message) = ($1, $2);
			$message =~ s/-+$//;
			if ($message =~ /^TMP([\d\.]+)/) {
				my $temperature = $1;
				my $timestamp = time();
				
				$last{$station.'.'.$index} = 0 unless $last{$station.'.'.$index};
				if (($timestamp - $last{$station.'.'.$index}) > $storeInterval) {
					print "db.heat.insert({ \"ts\" : \"$timestamp\", \"sensor\" : \"$station.$index\", \"val\": \"$temperature\" })\n";
					$last{$station.'.'.$index} = $timestamp;
				}
			} else {
				print STDERR "> $station > $message\n" if $verbose;
			}

			$saw = substr($saw, 12);
			$twelve = substr($saw, 0, 12);
			$index++;
		}
        } else {
                $timeout--;
        }
}

if ($timeout == 0) {
        die "Waited $STALL_DEFAULT seconds and never saw what I wanted\n";
}

$PortObj->close || warn "failed to close";
undef $PortObj;     
