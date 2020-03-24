#!/usr/env perl
# Covid-19  JHU CSSE Data Transformer
# converts daily updated data obtained from 
# CSSEGISandData/COVID-19

=pod
This application creates a clone of the COVID-19 dataset at the CSSE
of John Hopkins University. It updates the clone if one already exists.
It converts the dataset to Storable, JSON and Data::Dumper files
for use in other scripts

=cut
 
use strict; use warnings;
use lib "../lib/";
use Cwd qw(getcwd);
use Storable;
use Text::CSV;
my $csv = Text::CSV->new({ sep_char => ',' });

my $directorySeparator= ($^O=~/Win/)?"\\":"/";  

chdir "..$directorySeparator..$directorySeparator";
my $workingDirectory=getcwd();

my $dataFolder="$workingDirectory/Covid19Epidemiology$directorySeparator"."data".$directorySeparator."JHU-CSSE".$directorySeparator;
mkdir $dataFolder unless -d $dataFolder;

downloadDataSet();
extractData();


sub extractData{
	my $source="$workingDirectory/COVID-19/csse_covid_19_data/csse_covid_19_time_series/";
	print $source;
	foreach my $csvFile (<$source*.csv>){
		my ($file,$dir,$extension)=pathToFileDirExtension ( $csvFile );
		my %data=();
		open(my $fh, '<:encoding(UTF-8)', $csvFile) or die "Could not open file '$csvFile' $!";
		my @titles=split ",",<$fh>;
		while (my $line=<$fh>){
			if ($csv->parse($line)) {
				my @values = $csv->fields();
				$values[0] ="All" if $values[0] eq "";
				@{$data{$values[1]}{$values[0]}}{qw/latitude longitude/}=($values[2],$values[3]);
				@{$data{$values[1]}{$values[0]}{numbers}}{@titles[4..$#titles]}=@values[4..$#titles];
				}
			else {
				warn "Line could not be parsed: $line\n";
			}
		}
		
		convertAndSave(\%data,$file);
   }
}

sub convertAndSave{
	my ($dataRef,$file)=@_;
		print "Saving data from file $file\n";
	store $dataRef, $dataFolder.$file.".stor" or die "Could not open file ".$dataFolder.$file.".stor"." $!";
	eval "use JSON";
	if ($@){
		print "\nJSON perl module not available\n"
	}
	else {
		my $JSONdata = encode_json($dataRef);
		open(my $of,">".$dataFolder.$file.".json") or die "Could not open file ".$dataFolder.$file.".json"." $!";;
		print $of $JSONdata;
		close($of);
	}
	eval "use Data::Dumper qw(Dumper);";
	if ($@){
		print "\nData::Dumper perl module not available\n"
	}
	else {
		my $dumped = Dumper ($dataRef);
		open(my $of,">".$dataFolder.$file.".dump") or die "Could not open file ".$dataFolder.$file.".dump"." $!";
		print $of $dumped;
		close($of);
	}
}


sub downloadDataSet{
	if (-e "COVID-19"  and -d "COVID-19"  ){
		print "COVID-19 clone found; attempting to update\n";
		chdir "COVID-19";
	    `git pull`;
	}
	else {print "Attempting to clone repo https://github.com/CSSEGISandData/COVID-19\n";	
		if (`git clone https://github.com/CSSEGISandData/COVID-19`){
			print "Success downloading Data Set\n";
		}
		else { print "failed to clone\n";}
	}
}

sub pathToFileDirExtension{  #returns filename, directory and extension
	my $path=shift;
	$path=~/^(.*)$directorySeparator([^$directorySeparator]+)\.([a-z]*)$/i;
	return ($2."\.".$3,$1,$3);
}
