#!/usr/env perl
# Covid-19  JHU CSSE Data Transformer
# converts daily updated data obtained from 
# CSSEGISandData/COVID-19

=pod
This application creates a clone of the COVID-19 dataset at the CSSE
of John Hopkins University. It updates the clone if one already exists.
It converts the dataset to Storable, JSON and Data::Dumper files.
If called with a parameter it can extract specific rows of data

=cut
 
use strict; use warnings;
use lib "../lib/";
use Storable;
use Text::CSV;
my $csv = Text::CSV->new({ sep_char => ',' });

my $directorySeparator= ($^O=~/Win/)?"\\":"/";  

my $dataFolder="..$directorySeparator"."data".$directorySeparator."JHU-CSSE".$directorySeparator;
mkdir $dataFolder;
my $workingDirectory="..$directorySeparator..$directorySeparator";

my $source=$workingDirectory."COVID-19/csse_covid_19_data/csse_covid_19_time_series/";
foreach my $csvFile (<$source*.csv>){
	my ($file,$dir,$extension)=pathToFileDirExtension ( $csvFile );
	my %data;
	open(my $fh, '<:encoding(UTF-8)', $csvFile) or die "Could not open file '$csvFile' $!";
	my @titles=split ",",<$fh>;
	while (my $line=<$fh>){
		if ($csv->parse($line)) {
			my @values = $csv->fields();
			$values[0] ="All" if $values[0] eq "";
			@{$data{$values[1]}{$values[0]}}{qw/latitude longitude/}=($values[2],$values[3]);
			@{$data{$values[1]}{$values[0]}}{@titles[4..$#titles]}=@values[4..$#titles];
			}
		else {
			warn "Line could not be parsed: $line\n";
		}
	}
	
	store \%data, $dataFolder.$file.".stor";
	eval "use JSON";
	unless ($@){
		my $JSONdata = encode_json(\%data);
		open(my $of,">".$dataFolder.$file.".json");
		print $of $JSONdata;
		close($of);
	}
}

sub downloadDataSet{
	chdir $workingDirectory;
	if (-e $workingDirectory.$directorySeparator."COVID-19"  and -d $workingDirectory.$directorySeparator."COVID-19"  ){
		print "COVID-19 clone found; attempting to update\n";
		chdir  $workingDirectory.$directorySeparator."COVID-19";
	    `git pull`;
	}
	else {print "Attempting to clone repo https://github.com/CSSEGISandData/COVID-19\n";	
		my $response= `git clone https://github.com/CSSEGISandData/COVID-19`;
		if ($response !~/fatal/g){
			print "Success downloading Data Set\n";
		};
	}
}

sub pathToFileDirExtension{  #returns filename, directory and extension
	my $path=shift;
	$path=~/^(.*)$directorySeparator([^$directorySeparator]+)\.([a-z]*)$/i;
	return ($2."\.".$3,$1,$3);
}
