#!/usr/bin/perl -w
use HTML::Template;
use Time::Local;

my $LOGFILE = '/Users/jaldama/Desktop/Projects/NagiosParse/log';
my $downTime = 0;
my $upTime = 0;
my $totalDownTime = 0;
my $serviceName = 0;
my %downTimeHash = ();
my $startTime =0;

my $downPercentage = 0;
my $upPercentage = 0;

($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$year += 1900;
print "$sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst\n";
$now_string = localtime; 
my $currentMonth = sprintf("%02d",$mon+1);
my $currentYear = sprintf("%04d", $year);
my $epochTime = time-timelocal(0,0,0,1,$mon,$year);



open(LOGFILE, $LOGFILE) or die ("Couldn't open the file.");

if (<LOGFILE> =~ /\[(\d*)\]*/) {
	$startTime = $1;
}

foreach my $line (<LOGFILE>) {
	chomp($line);

	#Host Alert gives either UP or DOWN
	if ($line=~/\s*;DOWN*/ && ($line=~/HOST\ ALERT:\s+([^;]+)/)) {
		if ($line=~/\[(\d*)\]*/) {
			$downTime = $1;
		}
		#Get service that went down
		if ($line=~/HOST\ ALERT:\s+([^;]+)/) {
			$serviceName = $1;
		}
		
		#Add service and down time to hash
		$downTimeHash{$serviceName}=$downTime;
	}
	
	#Service Alert gives Unknown, Critical, Ok
	if ($line=~/SERVICE\ ALERT:\s+([^;]+)/ &&($line=~/\s*;CRITICAL*/ || $line=~/\s*;UNKNOWN*/)) {
		if ($line=~/\[(\d*)\]*/) {
			$downTime = $1;
		}
		if ($line=~/SERVICE\ ALERT:\s+([^;]+)/) {
			$serviceName = $1;
		}
		
		#Add service and down time to hash
		$downTimeHash{$serviceName}=$downTime;
		
	}

	#Check if line is a service that's gone back Up 
	#and it's downtime is already in the hash
	
	if (($line=~/\s*;UP*/ && $line=~/HOST\ ALERT:\s+([^;]+)/) || ($line=~/SERVICE\ ALERT:\s+([^;]+)/ && $line=~/\s*;OK*/)) {
		if ($line=~/\[(\d*)\]*/) {
			$upTime = $1;
		}
		if (exists $downTimeHash{$serviceName}) {
			#service went down, calculate total down time
			#subtract uptime from downtime
			my $tempTime = $upTime - $downTimeHash{$serviceName};
			$totalDownTime += $tempTime;
		}
	}
		
}

$downPercentage = $totalDownTime/$epochTime;
$upPercentage = 100-$downPercentage;



my $template = HTML::Template->new(filename => 'nagiosStatus.tmpl');
$template->param(UPTIME => $upPercentage);
print $template->output;