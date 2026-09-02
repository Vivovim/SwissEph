#!/usr/bin/perl -w
## Sat Jul 25 02:48:07 PM MST 2026
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


my $now = time;


my ($seconds, $minutes, $hours, $day_of_month, $month, $year, $wday, $yday, $isdst) = localtime($now);



my $yearx = $year + 1900;
my $monthx = $month + 1;

my $day = 1;


my $lat = 34.5394;
my $lon = -112.4683;

my $elev = 1713;





system("moonrise_moonset_table.pl --lat $lat --lon $lon --elev $elev --days 5");


exit(0);


