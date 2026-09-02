#!/usr/bin/env perl


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
use warnings;
use feature qw(say);

use Config;
use FindBin qw($Bin);
use Getopt::Long qw(GetOptions);
use Time::Piece;
use lib "$Bin/local/lib/perl5", "$Bin/local/lib/perl5/$Config{archname}";

use SwissEph qw(:all);

my $HAS_SWIEPH = eval { my $flag = SEFLG_SWIEPH; defined $flag } ? 1 : 0;

my %opt = (
    ephe_path => $ENV{SE_EPHE_PATH},
);

GetOptions(
    'ephe-path=s' => \$opt{ephe_path},
) or die usage();

if (defined $opt{ephe_path} && length $opt{ephe_path}) {
    swe_set_ephe_path($opt{ephe_path});
}

my $utc_now = gmtime(time);
my $jd = utc_to_jd($utc_now);
my $iflag = base_iflag(\%opt) | SEFLG_SPEED;

my @planets = (
    [ SE_MERCURY(), 'Mercury' ],
    [ SE_VENUS(),   'Venus'   ],
    [ SE_MARS(),    'Mars'    ],
    [ SE_JUPITER(), 'Jupiter' ],
    [ SE_SATURN(),  'Saturn'  ],
    [ SE_URANUS(),  'Uranus'  ],
    [ SE_NEPTUNE(), 'Neptune' ],
    [ SE_PLUTO(),   'Pluto'   ],
);

say 'Timestamp (UTC): ' . $utc_now->strftime('%Y-%m-%d %H:%M:%S');

for my $planet (@planets) {
    my ($planet_id, $label) = @$planet;
    my $calc = swe_calc_ut($jd, $planet_id, $iflag);

    die "SwissEph planet calc failed for $label: $calc->{serr}\n"
        if defined $calc->{serr} && length $calc->{serr};

    my $longitude_speed = $calc->{xx}->[3];
    my $status = $longitude_speed < 0 ? 'Retrograde' : 'Direct';

    say sprintf('%-8s %s', $label . ':', $status);
}

swe_close();

sub utc_to_jd {
    my ($utc_time) = @_;

    my $jd = swe_utc_to_jd(
        $utc_time->year,
        $utc_time->mon,
        $utc_time->mday,
        $utc_time->hour,
        $utc_time->min,
        $utc_time->sec + 0,
        SE_GREG_CAL,
    );

    die "SwissEph UTC->JD failed: $jd->{serr}\n"
        if defined $jd->{serr} && length $jd->{serr};

    return $jd->{tjd_ut};
}

sub base_iflag {
    my ($opt) = @_;
    return SEFLG_SWIEPH if $HAS_SWIEPH && defined $opt->{ephe_path} && length $opt->{ephe_path};
    return SEFLG_MOSEPH;
}

sub usage {
    return <<'USAGE';
Usage:
  perl planet_retrograde_status.pl [--ephe-path PATH]

Print each planet's direct/retrograde status at the current UTC timestamp.
USAGE
}
