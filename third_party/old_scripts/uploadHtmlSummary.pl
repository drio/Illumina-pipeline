#!/usr/bin/env perl

# EXAMPLE to Run: "perl ./uploadHtmlSummary.pl FC3034FAAXX-2 Summary.html"

#INPUT:
# Flowcell/Lane Barcode
# - Barcode of the FlowCell(Ex: FC3034FAAXX)/Lane(which is the flowcell barcode plus the addition of the lane number EX: FC3034FAAXX-1,FC3034FAAXX-2...)
# - Full path needs to specified for Summary html file(EX: /Users/jakkamse/Desktop/Summary.html)

# Create user agent object
use LWP::UserAgent;
use URI::Escape;
use Strict;

if( @ARGV !=2 ) {
print "usage: $0 barcode file_name\n";
exit;
}

my $data_file= $ARGV[1];
unless ($data_file =~ /^.+\.\w+$/) {
     print "Please give a  file";
     exit;
}

open(DAT, $data_file) || die("Could not open file!");
@raw_data=<DAT>;
close(DAT);

foreach $wrestler (@raw_data)
{
    chomp($wrestler);
    ($w_name,$crowd_re,$fav_move)=split(/\|/,$wrestler);
    $file_content .= "$w_name\n";
}

my $ua = new LWP::UserAgent;
my $uploadhtmlURL = "http://10.10.53.190:8080/ngenlims/edu.bcm.hgsc.gwt.lims454.NGenLimsGwt/uploadHtml";
my $response = $ua ->post($uploadhtmlURL, {barcode => $ARGV[0],file_name => $ARGV[1] ,file_content => $file_content});

if(not $response->is_success ) {print "Error: Cannot connect\n"; exit(0);}

my $textStr= $response->content;
$textStr=~/^\s*(.+)\s*$/;
$textStr=$1;
print "$textStr\n";


