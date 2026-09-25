#!/usr/bin/perl 
## Sun Jun  7 11:27:13 PDT 2009
## Christopher ctopher@mac.com
## Re-Wrote This Code on Fri September 16, 2011 @ 20:02:35
## should be Faster and Lightweight.
## Bored Stupid!!
## updated this file for faster Sat, September 24, 2011 @ 13:33:52


# Copyright (C) 2026 Neo Ctopher
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# under the terms of the GNU Affero General Public License,
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# See the GNU Affero General Public License in the LICENSE file
# distributed with this repository.
#
# This software uses the Swiss Ephemeris.
# Swiss Ephemeris is Copyright Astrodienst AG.
# See: https://www.astro.com/swisseph/




use strict;
use DBI;
# use Astro::MoonPhase qw( phase );
use lib '/home/ctopher/bin/modules/';
use MoonAge qw(moon_age_days);

my $file      = "/tmp/xxyzzyj.txt";
my $saved_log = "/home/alex/saved_log.txt";
my $line      = "";
my $list      = "";

system('clear');

print "Christopher's Journal Software!!\n";
print
"This software uses vim; like vi,\nif you don't know how to use it,\nabort now.\ntype control-C to abort.\n\n";

print <<"END_ASCII";
 _   _                           
| \\ | | ___  ___    
|  \\| |/ _ \\/ _ \\  
| |\\  |  __/ (_)\|    
|_| \\_|\\___|\\___\/     


	NEO
                                     

END_ASCII








{

    package Startup;

    sub New {

        my $class = shift;
        my $self  = {};
        bless( $self, $class );
        return ( $class, $self );
    }

    sub GetKeys {

        my %catagory = (
            "1" => "Personal",
            "2" => "Public",
            "3" => "Intellectual",
            "4" => "Gratitude",
            "5" => "Moon Work",
            "6" => "New Age",
            "7" => "Computer_Talk"
        );

        my @keysin = keys %catagory;
        my @sorted = sort { $a <=> $b } @keysin;

        foreach my $key (@sorted) {
            my $value = $catagory{$key};
            print "$key: $value\n";
        }

        my $answer = "";
        print "enter your # answer--->: ";
        chomp( $answer = <STDIN> );
#####

        if ( $answer =~ /\d/ ) {

            my ( $match, $found, $item );

            $match = $answer;
            foreach my $item (@keysin) {

                if ($answer) {

                    $match = $item;
                    $found = 1;

                    last;

                }

            }

            if ($found) {
                return $catagory{$answer};

            }
            else {

                print "Error!! Try again!!\n";
                exit(0);

            }

        }
        else {

            print "ERROR: BAD INPUT.\n";
            exit(0);

        }

#####
        #return $catagory{$answer};

    }

}

my $setup = Startup->New();

my $answ = $setup->GetKeys();

&journal($answ);

sub journal {
    my $catagory = shift;

    # Set the start timer for the Journal entry.
    #	my $test = time;

    # Ask for a subject
    print "Connected\n";
    print "Enter a subject: ";
    my $subject = "";

    chomp( $subject = <STDIN> );

    my $test = time;

    system("vim $file");
    open( FI, $file ) || die "sorry dave couldn't do that $file $!";

    while (<FI>) {
        $line .= $_;
    }

    my ( $date, $time, $duration, $tlot ) = SetTime($test);

    my $wc1 = `wc -w $file`;
    $wc1 =~ s/\s+//g;
    $wc1 =~ s/\D+//g;

    my $wpm = "0";

    $wpm = $wc1 / $tlot;

#####################

    my $timexx = time;
    my $timex  = $timexx + 22680;


my $age_days = moon_age_days();

## Moon Phase Stuff here!
#    my (
#        $moonphase, $moonillum, $moonage1, $moondist,
#        $moonang,   $sundist,   $sunang
#    ) = phase($timexx);

    # print "MoonPhase: $moonphase, Moon Age: $moonage\n";
#    my $moonage = sprintf( "%.2f", $moonage1 );
    my $moonage = sprintf( "%.2f", $age_days );

######################

    # clear the screen when done!

    my $res = &SetStone(
        $date,     $time,    $duration, $wc1, $wpm,
        $catagory, $subject, $line,     $moonage, $timexx
    );

    system("digital_noise.pl");
    my $result33 = system('clear');

    # print some stuff after the screen clears.
    # print "Status: $result33\t";
    print "Time = $time\n";
    print "Data Saved To Database: $date\n";
    print "Database Result = $res\n";
    print "Words: $wc1: WPM: $wpm\n";

 # open (FO, ">>$saved_log") || die "Sorry no way to output file $saved_log $!";
 # print some stuff after the screen clears.
 # print FO "Status: $result33\t";
 # print FO "Time = $time\n";
 # print FO "$subject\n";
 # print FO "Data Saved To Database: $date\n";
 # print FO "Database Result = $res\n";
 # print FO "Words: $wc1: WPM: $wpm\n";
 # print FO "End log----------------------------------!!!!!!\n";
 # close(FO);

}

sub SetStone {

    my ( $date, $time, $duration, $wc1, $wpm, $catagory, $subject, $line, $age, $ts )
      = @_;

    my $dsn = "DBI:mysql:host=localhost;database=__DB__";
    my $dbh = DBI->connect( $dsn, "__USERNAME__", "__PASSWORD__" )
      or die "can not connect to server.\n";

my $sentiment = "0";

#my $dbh = DBI->connect('dbi:SQLite:dbname=/Users/ctopher/bin/cth_Data.db', '', '', {AutoCommit=>1, RaiseError=>1, printError=>0});

    my $sth = $dbh->prepare(
"INSERT INTO data (date, time, duration, wc, wpm, catagory, subject, body, moonp, times, sentiment) VALUES (?,?,?,?,?,?,?,?,?,?,?)"
    );
    $sth->execute(
        $date,     $time,    $duration, $wc1, $wpm,
        $catagory, $subject, $line,     $age, $ts, $sentiment
    );

    return ("True");

}

sub SetTime {
    my @list = ();
    my $test = shift;

    # the time functions for the app.
    my ( $sec, $min, $hour, $DAY, $MONTH, $YEAR ) =
      (localtime)[ 0, 1, 2, 3, 4, 5 ];
    my $rmonth = $MONTH + 1;
    my $ryear  = $YEAR + 1900;
    my ( $fsec, $fmin, $fhour ) = (localtime)[ 0, 1, 3 ];
    my $test2    = time;
    my $alot     = $test2 - $test;
    my $tlot     = $alot / "60";
    my $date     = $rmonth . "-" . $DAY . "-" . $ryear;
	my $rrtlot	= sprintf("%.4f", $tlot);
    my $duration = $alot . "-" . $rrtlot;
    my $time     = $hour . ":" . $min . ":" . $sec;

    return ( $date, $time, $duration, $tlot );

}

system("rm $file");
exit(0);
