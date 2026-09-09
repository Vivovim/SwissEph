#!/usr/bin/perl -w
## Mon Jul 27 03:19:55 PM MST 2026
## Neo Ctopher neo@ctopher.me 

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

my $lat = 34.5394;
my $lon = -112.4683;
my $elev = 1645;
my $houses = "E";

my $now = time;
my ($seconds, $minutes, $hours, $day_of_month, $month, $year, $wday, $yday, $isdst) = localtime($now);


# $month = 0;


my $yearx = $year + 1900;
my $monthx = $month + 1;

my $yearb;

if ($month >= 1) {

	$month = $month;
	$yearb = $yearx;


#	print "$month\n";

} else {

	$month = 12;
	$yearb = $yearx - 1;

#	print "$month\n";

}


system("moon_phase_calendar.pl --lat $lat --lon $lon --elev $elev --month $month --year $yearb --house-system $houses");

system("moon_phase_calendar.pl --lat $lat --lon $lon --elev $elev --month $monthx --house-system $houses");


exit(0);



