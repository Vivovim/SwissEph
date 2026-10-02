#!/usr/bin/perl -wT
## Fri Dec  1 22:44:30 MST 2023
## Christopher ctopher@mac.com

use strict;






my $Input	= <@ARGV>;


my ($day1, $month1, $year1) = split(/:/, $Input);

	my $day		= substr( $day1, 0, 2);
	my $month	= substr( $month1, 0, 2);
	my $year	= substr( $year1, 0, 4);

if ($day =~ /^\d{2}$/) {


	$day = $day;

	} else {
	# print "Bad Input: day\n";
	$day = "01";
	}


if ($month =~ /^\d{2}$/) {

	$month = $month;
	} else {
	# print "Bad Input: month\n";
	$month = "01";
	}


if ($year =~ /^\d{4}$/) {

	$year = $year;
	} else {
	# print "Bad Input: Year\n";
	$year = "1970";
}





# my $day	        = "04";
# my $month     	= "06";
# my $year       = "1975";







my $date = "$day\-$month\-$year";





&RackSet($date);




















sub RackSet() {


my $date = shift;




my ($d1, $d2, $d3) = split(/-/, $date);

# print "$d1,$d2,$d3\t";

my $G1 = "";
my $G2 = "";

if ($d1 == "11" || $d1 == "22" || $d1 == "33") {

	$G1 = $d1;

} else {


my ($S1, $S2)	= split(//, $d1);
$G1 = $S1 + $S2;


}

# print "$G1\n";



if ($d2 == "11" || $d2 == "22" || $d2 == "33") {

		$G2 = $d2;

} else {

my ($S3, $S4)	= split(//, $d2);
$G2 = $S3 + $S4;


}


# print "$G2\n";






my ($S5, $S6, $S7, $S8)	= split(//, $d3);

my $G3 = $S5 + $S6 + $S7 + $S8;

# print "$G3\n";




my $num	= $G1 + $G2 + $G3;

# print "Num: $num\n";



if ($num == "11" || $num == "22" || $num == "33") {

	print "$num";


} else {


my ($a, $b) = split(//, $num);

	my $here = $a + $b;

	print "$here";


}

















}

