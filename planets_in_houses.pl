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
use POSIX qw(floor tzset);
use Time::Local qw(timegm timelocal);
use Time::Piece;
use lib "$Bin/local/lib/perl5", "$Bin/local/lib/perl5/$Config{archname}";

use SwissEph qw(:all);

my $LOCAL_TZ = 'America/Phoenix';
set_timezone($LOCAL_TZ);
my $HAS_SWIEPH = eval { my $flag = SEFLG_SWIEPH; defined $flag } ? 1 : 0;
my $now = time;

my %opt = (
    elev         => 0,
    datetime     => undef,
    ephe_path    => $ENV{SE_EPHE_PATH},
    house_system => 'P',
    topocentric  => 1,
);

GetOptions(
    'lat=f'          => \$opt{lat},
    'lon=f'          => \$opt{lon},
    'elev=f'         => \$opt{elev},
    'datetime=s'     => \$opt{datetime},
    'ephe-path=s'    => \$opt{ephe_path},
    'house-system=s' => \$opt{house_system},
    'topocentric!'   => \$opt{topocentric},
) or die usage();

for my $required (qw(lat lon)) {
    die usage() unless defined $opt{$required};
}

$opt{house_system} = uc substr($opt{house_system}, 0, 1);

if (defined $opt{ephe_path} && length $opt{ephe_path}) {
    swe_set_ephe_path($opt{ephe_path});
}

my $timestamp_local = parse_datetime($opt{datetime}, $now);
my $timestamp_utc = gmtime($timestamp_local->epoch);
my $jd = utc_to_jd($timestamp_utc);

my $iflag = base_iflag(\%opt) | SEFLG_SPEED;
if ($opt{topocentric}) {
    swe_set_topo($opt{lon}, $opt{lat}, $opt{elev});
    $iflag |= SEFLG_TOPOCTR;
}

my $houses = swe_houses_ex(
    $jd->{tjd_ut},
    $iflag,
    $opt{lat},
    $opt{lon},
    $opt{house_system},
);

die "SwissEph houses failed: $houses->{serr}\n"
    if defined $houses->{serr} && length $houses->{serr};

my $ecl_nut = swe_calc_ut($jd->{tjd_ut}, SE_ECL_NUT, base_iflag(\%opt));
die "SwissEph obliquity failed: $ecl_nut->{serr}\n"
    if defined $ecl_nut->{serr} && length $ecl_nut->{serr};

my $eps_true = $ecl_nut->{xx}->[0];

my @planets = (
    [ SE_SUN(),     'Sun'     ],
    [ SE_MOON(),    'Moon'    ],
    [ SE_MERCURY(), 'Mercury' ],
    [ SE_VENUS(),   'Venus'   ],
    [ SE_MARS(),    'Mars'    ],
    [ SE_JUPITER(), 'Jupiter' ],
    [ SE_SATURN(),  'Saturn'  ],
    [ SE_URANUS(),  'Uranus'  ],
    [ SE_NEPTUNE(), 'Neptune' ],
    [ SE_PLUTO(),   'Pluto'   ],
);

say "Timestamp ($LOCAL_TZ): " . $timestamp_local->strftime('%Y-%m-%d %H:%M:%S');
say "Timestamp (UTC): " . $timestamp_utc->strftime('%Y-%m-%d %H:%M:%S');
say sprintf(
    "Location: lat %.6f, lon %.6f, elev %.1f m",
    $opt{lat},
    $opt{lon},
    $opt{elev},
);
say "House system: " . swe_house_name($opt{house_system}) . " ($opt{house_system})";
say sprintf("Ascendant: %s", format_longitude($houses->{asc}));
say sprintf("Midheaven: %s", format_longitude($houses->{mc}));
say "";
say "House cusps:";
for my $house_num (1 .. 12) {
    my $cusp = $houses->{cusps}->[$house_num];
    say sprintf("  %2d: %s", $house_num, format_longitude($cusp));
}

say "";
say "Planets:";
for my $planet (@planets) {
    my ($planet_id, $label) = @$planet;
    my $calc = swe_calc_ut($jd->{tjd_ut}, $planet_id, $iflag);
    die "SwissEph planet calc failed for $label: $calc->{serr}\n"
        if defined $calc->{serr} && length $calc->{serr};

    my ($ecl_lon, $ecl_lat) = @{ $calc->{xx} }[0, 1];
    my $house = swe_house_pos(
        $houses->{armc},
        $opt{lat},
        $eps_true,
        $opt{house_system},
        $ecl_lon,
        $ecl_lat,
    );

    die "SwissEph house assignment failed for $label: $house->{serr}\n"
        if defined $house->{serr} && length $house->{serr};

    say sprintf(
        "  %-8s %-17s house %2d (%s, %.4f)",
        $label,
        format_longitude($ecl_lon),
        $house->{ihno},
        format_house_position($house->{dhpos}),
        $house->{dhpos},
    );
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

    return $jd;
}

sub base_iflag {
    my ($opt) = @_;
    return SEFLG_SWIEPH if $HAS_SWIEPH && defined $opt->{ephe_path} && length $opt->{ephe_path};
    return SEFLG_MOSEPH;
}

sub parse_datetime {
    my ($input, $epoch_now) = @_;

    return localtime($epoch_now) unless defined $input && length $input;

    my $normalized = normalize_datetime($input);
    my ($year, $month, $day, $hour, $minute, $second, $is_utc) =
        $normalized =~ /\A(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(Z?)\z/
        or die "Unsupported datetime format. Use local Phoenix time like 2026-07-26T01:20:42\n";

    my $epoch = $is_utc
        ? timegm($second, $minute, $hour, $day, $month - 1, $year)
        : timelocal($second, $minute, $hour, $day, $month - 1, $year);

    return localtime($epoch);
}

sub normalize_datetime {
    my ($input) = @_;

    if ($input =~ /\A(\d{4}-\d{2}-\d{2})[T ](\d{1,2}):(\d{2}):(\d{2})(Z?)\z/) {
        return sprintf('%sT%02d:%02d:%02d%s', $1, $2, $3, $4, $5);
    }

    return $input;
}
sub set_timezone {
    my ($tz) = @_;
    $ENV{TZ} = $tz;
    tzset();
}

sub format_house_position {
    my ($dhpos) = @_;

    my $fraction = $dhpos - int($dhpos);
    $fraction += 1 if $fraction < 0;

    my $total_seconds = int(($fraction * 30 * 3600) + 0.5);
    $total_seconds = 0 if $total_seconds >= 30 * 3600;

    my $degrees = int($total_seconds / 3600);
    my $minutes = int(($total_seconds % 3600) / 60);
    my $seconds = $total_seconds % 60;

    return sprintf('%02dd %02dm %02ds', $degrees, $minutes, $seconds);
}

sub format_longitude {
    my ($longitude) = @_;

    my @signs = qw(Aries Taurus Gemini Cancer Leo Virgo Libra Scorpio Sagittarius Capricorn Aquarius Pisces);
    my $normalized = normalize_360($longitude);

    my $sign_index = int($normalized / 30);
    my $degrees_in_sign = $normalized - ($sign_index * 30);
    my $degrees = int($degrees_in_sign);
    my $minutes = int(($degrees_in_sign - $degrees) * 60);
    my $seconds = int((((($degrees_in_sign - $degrees) * 60) - $minutes) * 60) + 0.5);

    if ($seconds == 60) {
        $seconds = 0;
        $minutes++;
    }
    if ($minutes == 60) {
        $minutes = 0;
        $degrees++;
    }
    if ($degrees == 30) {
        $degrees = 0;
        $sign_index = ($sign_index + 1) % 12;
    }

    return sprintf('%2d %s %02dm %02ds', $degrees, $signs[$sign_index], $minutes, $seconds);
}

sub normalize_360 {
    my ($angle) = @_;
    $angle -= 360 * floor($angle / 360);
    $angle += 360 if $angle < 0;
    return $angle;
}

sub usage {
    return <<'USAGE';
Usage:
  perl planets_in_houses.pl --lat 47.3769 --lon 8.5417 --elev 408 \
    [--datetime 2026-07-26T01:20:42] [--ephe-path /path/to/ephe] \
    [--house-system P] [--topocentric]

Notes:
  --datetime defaults to the current America/Phoenix local time if omitted.
  --datetime without a timezone is interpreted as America/Phoenix.
  --datetime with a trailing Z is interpreted as UTC.
  --ephe-path defaults to $SE_EPHE_PATH when set.
  --house-system defaults to P (Placidus).
  --elev is meters above sea level.
  Longitude east is positive, west is negative.
USAGE
}
