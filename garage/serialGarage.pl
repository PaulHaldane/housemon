#!/usr/bin/perl -w

use Getopt::Long;

use Device::SerialPort qw( :PARAM :STAT 0.07 );

use strict;
use warnings;
use sigtrap qw/handler signal_handler normal-signals error-signals/;

my $verbose = 0;
my $tty = 'ttyAMA0';
my $storeInterval = 900;
my $baudrate = 9600;
my $tries = 300;
my $doorStateCurrent = 'unknown';
my $slackwebhook;

my $lastDweet = time();
my $dweetInterval = 1800;
my $dweetWebhook;

my %concentration;
my %temperature;

GetOptions (
	'verbose=i' => \$verbose,
	'storeInterval=i' => \$storeInterval,
	'baudrate=i' => \$baudrate,
	'tries=i' => \$tries,
	'slackwebhook=s' => \$slackwebhook,
	'dweetWebhook=s' => \$dweetWebhook,
	'tty=s' => \$tty
);

my $PortName = '/dev/'.$tty;
my $quiet = 0;
my $lockfile = '/tmp/'.$tty.'.lock';

my $PortObj = new Device::SerialPort($PortName, $quiet, $lockfile)
       || die "Can't open $PortName: $!\n";

sub signal_handler {
	if (defined($PortObj)) {
		$PortObj->close;
		undef $PortObj;     
	}
	print STDERR "\nGot signal\n";
	exit(0);
}

$PortObj->user_msg(1);
$PortObj->databits(8);
$PortObj->baudrate($baudrate);
$PortObj->parity("none");
$PortObj->stopbits(1);
$PortObj->handshake("rts");

my $STALL_DEFAULT = $tries; # how many intervals to wait for new input
 
my $timeout = $STALL_DEFAULT;
 
$PortObj->read_char_time(0);     # don't wait for each character
$PortObj->read_const_time(1000); # 1 second per unfulfilled "read" call
 
$| = 1;

my %last;

my $dots = 0;
while ($timeout > 0) {
	my $tempIndex;
	my $concIndex;
        my ($count, $saw) = $PortObj->read(255); # will read _up to_ 255 chars
	if ($verbose > 2) {
		if (($dots == 0) || ($count != 0)) {
			print STDERR "\n".localtime(time())." $count >>".$saw."<<";
			$dots++;
		} else {
			if (($dots % 5) == 0) {
				print STDERR '-';
			} else {
				print STDERR '.';
			}
			$dots++;
			if ($dots >= 30) {
				$dots = 0;
			}
		}
	}
        if ($count > 0) {

		$timeout = $STALL_DEFAULT;	# reset timer
		print STDERR "\n".localtime(time())." ##".$saw."##" if $verbose > 1;
		if ((length($saw) % 12) != 0) {
			print STDERR "\n".localtime(time())." >>".$saw."<<" if $verbose;
			next;
		}

		my $twelve = substr($saw, 0, 12);
		my $lastStation = '';
		$tempIndex = $concIndex = 0;
		while (length($twelve) > 0) {
			unless ($twelve =~ /^a(..)(.*)/) {
				print STDERR "\n".localtime(time())." >>".$twelve."<<" if $verbose;
				$saw = substr($saw, 12);
				$twelve = substr($saw, 0, 12);
				next;
			}
			my ($station, $message) = ($1, $2);
			if ($station ne $lastStation) {
				$tempIndex = $concIndex = 0;
				$lastStation = $station;
			}
			$message =~ s/-+$//;
			if ($message =~ /^CON([\d\.]+)/) {
				my $concentration = sprintf("%.2f", $1); # numbers less than 1 get sent without 0 before decimal point which causes problems for some JSON parsers
				my $timestamp = time();
				
				$last{$station.'.CONC.'.$concIndex} = 0 unless $last{$station.'.CONC.'.$concIndex};
				if (($timestamp - $last{$station.'.CONC.'.$concIndex}) > $storeInterval) {
					print "db.conc.insert({ \"ts\" : \"$timestamp\", \"sensor\" : \"$station.$concIndex\", \"val\": \"$concentration\" })\n";
					$last{$station.'.CONC.'.$concIndex} = $timestamp;
					$concentration{$station.'.'.$concIndex} = $concentration;
				}
				$concIndex++;
			} elsif ($message =~ /^TMP([\d\.]+)/) {
				my $temperature = sprintf("%.2f", $1);
				my $timestamp = time();
				
				$last{$station.'.TEMP.'.$tempIndex} = 0 unless $last{$station.'.TEMP.'.$tempIndex};
				if (($timestamp - $last{$station.'.TEMP.'.$tempIndex}) > $storeInterval) {
					print "db.heat.insert({ \"ts\" : \"$timestamp\", \"sensor\" : \"$station.$tempIndex\", \"val\": \"$temperature\" })\n";
					$last{$station.'.TEMP.'.$tempIndex} = $timestamp;
					$temperature{$station.'.'.$tempIndex} = $temperature;
				}
				$tempIndex++;
			} elsif ($message =~ /^DOOR(.+)/) {
				my $doorState = $1;
				if ($doorState ne $doorStateCurrent) {
					print "# change from $doorStateCurrent to $doorState\n";
					if ($slackwebhook && (length($slackwebhook) > 0)) {
						my $command = sprintf 'curl --silent --show-error -X POST --data-urlencode "payload={\"channel\": \"#sensors\", \"username\": \"sensors\", \"text\": \"Garage door is %s was %s\"}" %s', $doorState, $doorStateCurrent, $slackwebhook;
						my $slackResponse = `$command`;
						print "# Slack response $slackResponse\n";
					}
					$doorStateCurrent = $doorState;
				}
			} else {
				print STDERR "\n".localtime(time())." > $station > $message" if $verbose;
			}

			$saw = substr($saw, 12);
			$twelve = substr($saw, 0, 12);
		}
        } else {
                $timeout--;
        }
	if ((time() - $lastDweet) > $dweetInterval) {
		if ($dweetWebhook && (length($dweetWebhook) > 0)) {
			my $timestamp = time();
			my $dataJson = '{ ';
			my ($key, $value);
			while (($key, $value) = each(%concentration)) {
				$dataJson .= "\"CONC.$key\": $value, ";
			}
			while (($key, $value) = each(%temperature)) {
				$dataJson .= "\"TEMP.$key\": $value, ";
			}
			$dataJson .= "\"DOOR\": \"$doorStateCurrent\",";
			$dataJson .= "\"ts\": $timestamp ";
			$dataJson .= ' }';

			my $command = sprintf 'curl --silent --show-error -H "Content-Type: application/json" -X POST --data \'%s\' %s', $dataJson, $dweetWebhook;
			print "# $command\n";
			my $dweetResponse = `$command`;
			print "# dweet response $dweetResponse\n";
			$lastDweet = $timestamp;
		}
	}
}

if ($timeout == 0) {
        die "\n".localtime(time())." Waited $STALL_DEFAULT seconds and never saw what I wanted\n";
}

$PortObj->close || warn "failed to close";
undef $PortObj;     
