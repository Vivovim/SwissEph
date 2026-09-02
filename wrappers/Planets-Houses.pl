#!/usr/bin/perl -w
## Sun Jul 26 02:27:16 PM MST 2026
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

my $elev = 1713;


system("planets_in_houses.pl --lat $lat --lon $lon --elev $elev --house-system E");


exit(0);



