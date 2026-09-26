#!/usr/bin/perl -w
## Tue Dec 18 15:14:01 PST 2012
## Christopher ctopher@me.com

use strict;
use DBI;
use Time::Local;

###################

my ($t1, $t2, $t3, $t4, $t5, $t6, $t7, $t8, $t9)        = (localtime)[0,1,2,3,4,5,6,7,8];

# set month and year right!!
$t8 = $t8 + "1";
$t5 = $t5 + "1";
$t6 = $t6 + "1900";

my $Total       = "365";

my $leap        = $t6 % "4";


 if ($leap == "0" && $t8 > "60") {

       $t8 = $t8 + "1";
         $Total  = "366";
          } else {
                  $Total          = "365";
                   }


#
#
###################

my $Set_END	= &EpochB();
my $Here	= time;
my $SL		= $Set_END - $Here;





my $dsn = "DBI:mysql:host=localhost;database=__DB__";
my $dbh = DBI->connect ($dsn, "__USERNAME__", "__PASSWORD__")
or die "can not connect to server.\n";














my ($YEARS, $MONTHS, $WEEKS, $DAYS, $HOURS, $MINUTES, $SECONDS) = &Jokes2($SL);


# print "$YEARS, $MONTHS, $WEEKS, $DAYS, $HOURS, $MINUTES, $SECONDS\n\n";

my $sth = $dbh->prepare("INSERT INTO summer ( `years`, `months`, `weeks`, `days`, `hours`, `minutes`, `seconds`, `date`, `piday`, `piday2` ) VALUES (?,?,?,?,?,?,?,?,?,?)");
$sth->execute($YEARS, $MONTHS, $WEEKS, $DAYS, $HOURS, $MINUTES, $SECONDS, $Here, $Set_END, $SL);











###########################################

# date functions


sub Jokes2 {
my $SL		= shift;
our ($seconds, $minutes, $hours, $day, $month, $year) = (localtime)[0,1,2,3,4,5];
if ($day > "30") {
	$day = "30";
}

$year		= $year + "1900";
my $time	= timelocal($seconds, $minutes, $hours, $day, $month, $year);
my $setT	= $SL;
my $setC	= commify($setT);
my $MN		= $setT / "60";
my $HR		= $MN / "60";
my $DY		= $HR / "24";
my $YR2		= $DY / "365";
my $YR		= $t6 - "1970";
my $Weeks	= $DY / "7";
my $MTHS	= $DY / "30";
my $MN2		= commify($MN);
my $HR2		= commify($HR);
my $DY2		= commify($DY);



return($YR2, $MTHS, $Weeks, $DY2, $HR2, $MN2, $setC);




}







sub EpochA {

my $second		= "00";
my $minute		= "00";
my $hour		= "00";
my $day			= "01";
my $month		= "0";
my $year		= "1970";

my $epocha	= timelocal($second, $minute, $hour, $day, $month, $year);



return $epocha;


}

#####  2025-06-20 19:42:25 summer solscist 2025


sub EpochB {

my $second		= "36";
my $minute		= "24";
my $hour		= "1";
my $day			= "21";
my $month		= "05";
my $year		= "2026";

my $epochb	= timelocal($second, $minute, $hour, $day, $month, $year);



return $epochb;


}



###########################################







sub commify {
    my $text = reverse $_[0];
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text;
}



