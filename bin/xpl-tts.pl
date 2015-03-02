#!/usr/bin/perl -w
eval 'exec /usr/bin/perl -w -S $0 ${1+"$@"}'
  if 0;    # not running under some shell

use strict;

use POSIX;
use warnings;
use Getopt::Long;
use Pod::Usage;
use xPL::Client;
use URI::Escape; 

use Digest::SHA qw(sha1_hex);

our $VERSION = '0.12';

$| = 1;    # autoflush helps debugging


my %args = ( vendor_id => 'domolfax', device_id => 'tts');
my $interface;
my $help;
my $wait = 5; 
my $xpl;

#------------------------------------------------------------------------------------------------------------
#                                                   common functions
#------------------------------------------------------------------------------------------------------------

sub XplPrint($) {
	my ($msg) =@_;
	printf("%s %-8.8s %s\n", POSIX::strftime("%d/%m/%Y %H:%M:%S", localtime ) , "INFO", $msg); 
	
}

sub XplSystem($) {
	my ($cmd) = @_;
	#XplPrint("System \"$cmd\"");
	system($cmd);
	#XplPrint("System done ($?)\n");
}

sub XplNotifyError($$) {
	my ($msg) =@_;
	# light version just display error
	printf("%s %-8.8s %s\n", POSIX::strftime("%d/%m/%Y %H:%M:%S", localtime  ) , "ERROR", $msg); 
}



sub hub_found_response{
	XplPrint("Hub: response received");                         
	$xpl->remove_event_callback("hub_connect");
  	$xpl->remove_timer("hub_timeout");

	tts("La synthèse vocale est opérationnelle");
}

sub hub_timeout{
	XplNotifyError("fatal hub_timeout","");
}

sub tts_callback() {
	my %p   = @_;
	my $msg = $p{message};
	my $speech = $msg->field("speech");

	tts($speech); 
} 


sub getFilename($) {
	my ($msg) = @_;

	my $filename = sprintf("%s/%s.mp3" , "/tmp", sha1_hex($msg) ) ; 
	print "[$msg] : $filename\n";

	return $filename;
}

sub tts($) {
	my ($msg) = @_;
	XplPrint("TTS speed: $msg\n");

	my $file = $msg;
	my $speechEncode = uri_escape($msg); 

	my $filename = getFilename($msg);	


	unless (-f $filename) {
		XplPrint("Request file");
		XplSystem( qq{ wget -q -U Mozilla -O $filename "http://translate.google.com/translate_tts?ie=UTF-8&tl=fr&q=$speechEncode" } ); 
		XplSystem( qq{ ls -la $filename } ); 
	} else {
		XplPrint("File already available: $file");
	}
	
	XplSystem( "mpg321 $filename"); 
	
}

sub main() {

	# Create an xPL Client object
	$xpl = xPL::Client->new( %args) or die "Failed to create xPL::Client\n";


	GetOptions(
		'interface=s' => \$interface,
		'help|?|h'    => \$help,
	) or pod2usage(2);
	pod2usage(1) if ($help);


	$args{'interface'} = $interface if ($interface);

	# init 
	XplPrint("Hub: waiting for hub_found event ($wait sec)"); 
	$xpl->add_event_callback(id => 'hub_connect', event => 'hub_found', callback => \&hub_found_response);

	$xpl->add_xpl_callback( id        => "ttsCallback",
	        self_skip => 0, targetted => 0, 
		    callback  => \&tts_callback,
			filter    => {
				class        => "tts",
		} );

	$xpl->add_timer(id => 'hub_timeout', timeout => $wait, callback => \&hub_timeout);

	while(1) {
		XplPrint("start mainLoop");
		eval { $xpl->main_loop(); };
		XplPrint("MailLoop eval : $@ ") if $@;
		sleep(1);
	}

}

main(); 
