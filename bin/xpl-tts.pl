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


our $VERSION = '0.13';

$| = 1;    # autoflush helps debugging


my %args = ( vendor_id => 'domolfax', device_id => 'tts');
my $interface;
my $help;
my $wait = 5; 
my $xpl;

my $defaultVoice  = "eva"; 
my $defaultVolume = "60";

my $defaultPath   = "/var/cache/xpl-tts"; 

# TODO: property file
my %voices = (
	"google" => "http://translate.google.com/translate_tts?ie=UTF-8&tl=fr&q=#TEXT#", 
	"agnes"  => "http://www.voxygen.fr/sites/all/modules/voxygen_voices/assets/proxy/index.php?method=redirect&voice=Agnes&text=#TEXT#", 
	"loic"   => "http://www.voxygen.fr/sites/all/modules/voxygen_voices/assets/proxy/index.php?method=redirect&voice=Loic&text=#TEXT#",
	"papi"   => "http://www.voxygen.fr/sites/all/modules/voxygen_voices/assets/proxy/index.php?method=redirect&voice=Papi&text=#TEXT#",
	"electra" => "http://www.voxygen.fr/sites/all/modules/voxygen_voices/assets/proxy/index.php?method=redirect&voice=Electra&text=#TEXT#",
	"robot" => "http://www.voxygen.fr/sites/all/modules/voxygen_voices/assets/proxy/index.php?method=redirect&voice=Robot&text=#TEXT#",
	"sorciere" => "http://www.voxygen.fr/sites/all/modules/voxygen_voices/assets/proxy/index.php?method=redirect&voice=Sorciere&text=#TEXT#",
	"melodine" => "http://www.voxygen.fr/sites/all/modules/voxygen_voices/assets/proxy/index.php?method=redirect&voice=Melodine&text=#TEXT#",
	"ramboo" => "http://www.voxygen.fr/sites/all/modules/voxygen_voices/assets/proxy/index.php?method=redirect&voice=Ramboo&text=#TEXT#",
	"chut" => "http://www.voxygen.fr/sites/all/modules/voxygen_voices/assets/proxy/index.php?method=redirect&voice=Chut&text=#TEXT#",
	"yeti" => "http://www.voxygen.fr/sites/all/modules/voxygen_voices/assets/proxy/index.php?method=redirect&voice=Yeti&text=#TEXT#",
	"bicool" => "http://www.voxygen.fr/sites/all/modules/voxygen_voices/assets/proxy/index.php?method=redirect&voice=Bicool&text=#TEXT#",
	"philippe" => "http://www.voxygen.fr/sites/all/modules/voxygen_voices/assets/proxy/index.php?method=redirect&voice=Philippel&text=#TEXT#",
	"damien" =>"http://www.voxygen.fr/sites/all/modules/voxygen_voices/assets/proxy/index.php?method=redirect&voice=Damien&text=#TEXT#",
	"darkvador"=> "http://www.voxygen.fr/sites/all/modules/voxygen_voices/assets/proxy/index.php?method=redirect&voice=DarkVadoor&text=#TEXT#",

	"john" => "http://www.voxygen.fr/sites/all/modules/voxygen_voices/assets/proxy/index.php?method=redirect&voice=John&text=#TEXT#",
	"helene" => "http://www.voxygen.fr/sites/all/modules/voxygen_voices/assets/proxy/index.php?method=redirect&voice=Helene&text=#TEXT#",
	"eva" => "http://www.voxygen.fr/sites/all/modules/voxygen_voices/assets/proxy/index.php?method=redirect&voice=Eva&text=#TEXT#",

	"zozo" => "http://www.voxygen.fr/sites/all/modules/voxygen_voices/assets/proxy/index.php?method=redirect&voice=Zozo&text=#TEXT#",




	
	);

#------------------------------------------------------------------------------------------------------------
#                                                   common functions
#------------------------------------------------------------------------------------------------------------

sub XplPrint($) {
	my ($msg) =@_;
	printf("%s %-8.8s %s\n", POSIX::strftime("%d/%m/%Y %H:%M:%S", localtime ) , "INFO", $msg); 
}

sub XplError($) {
	my ($msg) =@_;
	printf("%s %-8.8s %s\n", POSIX::strftime("%d/%m/%Y %H:%M:%S", localtime  ) , "ERROR", $msg); 
}

sub XplSystem($) {
	my ($cmd) = @_;
	XplPrint("System \"$cmd\"");
	system($cmd);
	#XplPrint("System done ($?)\n");
}


sub hub_found_response{
	XplPrint("Hub: response received");                         
	$xpl->remove_event_callback("hub_connect");
  	$xpl->remove_timer("hub_timeout");

	tts($defaultVoice , "La synthèse vocale est opérationnelle",80);
}

sub hub_timeout{
	XplError("fatal hub_timeout (please verify xpl hub is running on localhost)");
}

sub tts_callback() {
	my %p   = @_;
	my $msg = $p{message};

	my $speech = $msg->field("speech");
	my $voice  = $msg->field("voice");
	my $volume = $msg->field("volume");

	tts($voice,$speech,$volume);
} 


sub getFilename($$$) {
	my ($voice,$msg,$ext) = @_;

	my $filename = sprintf("%s/%s.%s" , $defaultPath, sha1_hex($voice.$msg), $ext ) ; 
	XplPrint("[$voice][$msg] : $filename");

	return $filename;
}

sub writeFile($$) {
	my ($file,$content) = @_;
	open (my $fh, ">" , $file);
	print  $fh  $content;
	close $fh;
}

sub tts($$$) {
	my ($voice,$text,$volume) = @_;
	XplPrint("TTS voice:$voice volume:$volume text: $text\n");

	my $textEncode = uri_escape($text); 

	# verify voice
	unless (defined( $voices{$voice} ) ) {	
		XplError("unknown voice [$voice], fallback to default voice");
		$voice = $defaultVoice; 
	}

	my $ttsUrl = $voices{$voice}; 
	$ttsUrl =~ s/#TEXT#/$textEncode/; 

	my $filename = getFilename($voice,$text,"mp3");	
	my $descFile = getFilename($voice,$text,"dsc");

	unless (-f $filename) {
		XplPrint("Request file ");

		XplSystem( qq{ wget -q -U Mozilla -O $filename "$ttsUrl" } ); 
		XplSystem( qq{ ls -la $filename } ); 

		writeFile($descFile,qq{Voice:$voice\nText:$text} );

		
	
	} else {
		XplPrint("File already available: $filename");
	}
	
	XplSystem( "mpg321 $filename -g $volume"); 
	
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
