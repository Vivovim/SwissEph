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
use POSIX qw(floor);
use Time::Local qw(timelocal);
use Time::Piece;
use lib "$Bin/local/lib/perl5", "$Bin/local/lib/perl5/$Config{archname}";

my $SWISS_EPH_LOAD_ERROR;
BEGIN {
    eval {
        require SwissEph;
        SwissEph->import(':all');
        1;
    } or $SWISS_EPH_LOAD_ERROR = $@;
}

my $now = localtime(time);
my $LOCAL_TIME_LABEL = $now->strftime('%Z %z') || 'local time';

my %opt = (
    elev         => 0,
    ephe_path    => $ENV{SE_EPHE_PATH},
    house_system => 'P',
    month        => $now->mon,
    year         => $now->year,
);

GetOptions(
    'elev=f'         => \$opt{elev},
    'ephe-path=s'    => \$opt{ephe_path},
    'help|h'         => \$opt{help},
    'house-system=s' => \$opt{house_system},
    'lat=f'          => \$opt{lat},
    'lon=f'          => \$opt{lon},
    'month=i'        => \$opt{month},
    'year=i'         => \$opt{year},
) or die usage();

if ($opt{help}) {
    print usage();
    exit 0;
}

for my $required (qw(lat lon)) {
    die usage() unless defined $opt{$required};
}

die "--month must be between 1 and 12\n"
    if $opt{month} < 1 || $opt{month} > 12;

die "--year must be a four-digit year\n"
    if $opt{year} < 1000 || $opt{year} > 9999;

$opt{house_system} = uc substr($opt{house_system}, 0, 1);

require_swiss_eph();

if (defined $opt{ephe_path} && length $opt{ephe_path}) {
    swe_set_ephe_path($opt{ephe_path});
}

swe_set_topo($opt{lon}, $opt{lat}, $opt{elev});

my ($start_epoch, $end_epoch) = month_bounds_epoch($opt{year}, $opt{month});
my $start_local = localtime($start_epoch);
my $start_utc = gmtime($start_epoch);
my $end_utc = gmtime($end_epoch);
my $start_jd = utc_to_jd($start_utc);
my $end_jd = utc_to_jd($end_utc);

my @events = find_all_ingresses($start_jd, $end_jd, \%opt);

say sprintf('Planet Ingress Display for %s', $start_local->strftime('%B %Y'));
say sprintf(
    'Location: lat %.6f, lon %.6f, elev %.1f m',
    $opt{lat},
    $opt{lon},
    $opt{elev},
);
say 'House system: ' . house_system_label($opt{house_system});
say 'Ingress timing: geocentric zodiac longitude';
say 'House placement: topocentric planet position at the ingress moment';
say 'Ephemeris mode: ' . ephemeris_mode_label(\%opt);
say '';
say sprintf(
    '%-23s  %-10s  %-12s  %-5s',
    "Date/Time ($LOCAL_TIME_LABEL)",
    'Planet',
    'Zodiac Sign',
    'House',
);
say '-' x 58;

for my $event (@events) {
    say sprintf(
        '%-23s  %-10s  %-12s  %5d',
        format_jd_as_local_time($event->{jd}),
        $event->{planet},
        $event->{sign},
        $event->{house},
    );
}

say '(no ingresses found in the requested month)'
    if !@events;

swe_close();

sub find_all_ingresses {
    my ($start_jd, $end_jd, $opt) = @_;

    my @events;
    for my $planet (planet_definitions()) {
        push @events, find_planet_ingresses(
            $planet->{id},
            $planet->{label},
            $start_jd,
            $end_jd,
            $opt,
        );
    }

    return sort {
        $a->{jd} <=> $b->{jd}
            ||
        $a->{planet} cmp $b->{planet}
    } @events;
}

sub find_planet_ingresses {
    my ($planet_id, $label, $start_jd, $end_jd, $opt) = @_;

    my $step_days = 1 / 48;
    my $prev_jd = $start_jd;
    my $prev_raw = planet_longitude($planet_id, $prev_jd, $opt);
    my $offset = 0;
    my $prev_unwrapped = $prev_raw;
    my @events;

    while ($prev_jd < $end_jd) {
        my $jd = $prev_jd + $step_days;
        $jd = $end_jd if $jd > $end_jd;

        my $raw = planet_longitude($planet_id, $jd, $opt);
        if ($raw < $prev_raw - 180) {
            $offset += 360;
        }
        elsif ($raw > $prev_raw + 180) {
            $offset -= 360;
        }

        my $unwrapped = $raw + $offset;
        $unwrapped = unwrap_longitude_near($unwrapped, $prev_unwrapped);

        my $prev_zone = floor($prev_unwrapped / 30);
        my $zone = floor($unwrapped / 30);

        if ($zone != $prev_zone) {
            die sprintf(
                'Step size too large while scanning %s: crossed %d sign boundaries in one sample window',
                $label,
                abs($zone - $prev_zone),
            ) . "\n" if abs($zone - $prev_zone) > 1;

            my $boundary_abs = $zone > $prev_zone ? $zone * 30 : $prev_zone * 30;
            my $ingress_jd = refine_ingress_time(
                $planet_id,
                $prev_jd,
                $jd,
                $boundary_abs,
                $opt,
            );

            push @events, {
                house  => planet_house($ingress_jd, $planet_id, $opt),
                jd     => $ingress_jd,
                planet => $label,
                sign   => zodiac_sign_from_index($zone),
            };
        }

        $prev_jd = $jd;
        $prev_raw = $raw;
        $prev_unwrapped = $unwrapped;
    }

    return @events;
}

sub refine_ingress_time {
    my ($planet_id, $lo, $hi, $boundary_abs, $opt) = @_;

    my $flo = longitude_error($planet_id, $lo, $boundary_abs, $opt);
    my $fhi = longitude_error($planet_id, $hi, $boundary_abs, $opt);

    return $lo if abs($flo) < 1e-10;
    return $hi if abs($fhi) < 1e-10;

    my $jd = ($lo + $hi) / 2;

    for (1 .. 20) {
        my ($error, $speed) = longitude_error_and_speed($planet_id, $jd, $boundary_abs, $opt);
        return $jd if abs($error) < 1e-9;

        last if abs($speed) < 1e-9;

        my $next_jd = $jd - ($error / $speed);
        last if $next_jd <= $lo || $next_jd >= $hi;

        $jd = $next_jd;
    }

    for (1 .. 100) {
        my $mid = ($lo + $hi) / 2;
        my $fmid = longitude_error($planet_id, $mid, $boundary_abs, $opt);

        return $mid if abs($fmid) < 1e-10 || ($hi - $lo) * 86400 < 0.25;

        if (($flo < 0 && $fmid < 0) || ($flo > 0 && $fmid > 0)) {
            $lo = $mid;
            $flo = $fmid;
        }
        else {
            $hi = $mid;
            $fhi = $fmid;
        }
    }

    return ($lo + $hi) / 2;
}

sub planet_longitude {
    my ($planet_id, $jd, $opt) = @_;

    my $calc = swe_calc_ut($jd, $planet_id, base_iflag($opt));
    die "SwissEph planet calc failed: $calc->{serr}\n"
        if defined $calc->{serr} && length $calc->{serr};

    return normalize_360($calc->{xx}->[0]);
}

sub planet_house {
    my ($jd, $planet_id, $opt) = @_;

    my $iflag = house_iflag($opt);
    my $houses = swe_houses_ex(
        $jd,
        $iflag,
        $opt->{lat},
        $opt->{lon},
        $opt->{house_system},
    );
    die "SwissEph houses failed: $houses->{serr}\n"
        if defined $houses->{serr} && length $houses->{serr};

    my $ecl_nut = swe_calc_ut($jd, SE_ECL_NUT(), base_iflag($opt));
    die "SwissEph obliquity failed: $ecl_nut->{serr}\n"
        if defined $ecl_nut->{serr} && length $ecl_nut->{serr};

    my $calc = swe_calc_ut($jd, $planet_id, $iflag);
    die "SwissEph planet calc failed: $calc->{serr}\n"
        if defined $calc->{serr} && length $calc->{serr};

    my ($longitude, $latitude) = @{ $calc->{xx} }[0, 1];
    my $house = swe_house_pos(
        $houses->{armc},
        $opt->{lat},
        $ecl_nut->{xx}->[0],
        $opt->{house_system},
        $longitude,
        $latitude,
    );
    die "SwissEph house assignment failed: $house->{serr}\n"
        if defined $house->{serr} && length $house->{serr};

    return $house->{ihno};
}

sub longitude_error {
    my ($planet_id, $jd, $boundary_abs, $opt) = @_;

    my $longitude = unwrap_longitude_near(
        planet_longitude($planet_id, $jd, $opt),
        $boundary_abs,
    );

    return $longitude - $boundary_abs;
}

sub longitude_error_and_speed {
    my ($planet_id, $jd, $boundary_abs, $opt) = @_;

    my $calc = swe_calc_ut($jd, $planet_id, base_iflag($opt) | SEFLG_SPEED());
    die "SwissEph planet calc failed: $calc->{serr}\n"
        if defined $calc->{serr} && length $calc->{serr};

    my $longitude = unwrap_longitude_near(
        normalize_360($calc->{xx}->[0]),
        $boundary_abs,
    );
    my $error = $longitude - $boundary_abs;
    my $speed = $calc->{xx}->[3];

    return ($error, $speed);
}

sub month_bounds_epoch {
    my ($year, $month) = @_;

    my $start = timelocal(0, 0, 0, 1, $month - 1, $year);
    my ($next_year, $next_month) = $month == 12 ? ($year + 1, 1) : ($year, $month + 1);
    my $end = timelocal(0, 0, 0, 1, $next_month - 1, $next_year);

    return ($start, $end);
}

sub utc_to_jd {
    my ($utc_time) = @_;

    my $jd = swe_utc_to_jd(
        $utc_time->year,
        $utc_time->mon,
        $utc_time->mday,
        $utc_time->hour,
        $utc_time->min,
        $utc_time->sec + 0,
        SE_GREG_CAL(),
    );

    die "SwissEph UTC->JD failed: $jd->{serr}\n"
        if defined $jd->{serr} && length $jd->{serr};

    return $jd->{tjd_ut};
}

sub house_iflag {
    my ($opt) = @_;
    return base_iflag($opt) | SEFLG_TOPOCTR();
}

sub base_iflag {
    my ($opt) = @_;
    return SEFLG_SWIEPH() if defined $opt->{ephe_path} && length $opt->{ephe_path};
    return SEFLG_MOSEPH();
}

sub ephemeris_mode_label {
    my ($opt) = @_;
    return 'Swiss Ephemeris files (SEFLG_SWIEPH)' if base_iflag($opt) == SEFLG_SWIEPH();
    return 'Moshier fallback (SEFLG_MOSEPH)';
}

sub house_system_label {
    my ($system) = @_;
    return swe_house_name($system) . " ($system)";
}

sub unwrap_longitude_near {
    my ($longitude, $target) = @_;

    my $unwrapped = $longitude;
    $unwrapped -= 360 while $unwrapped - $target > 180;
    $unwrapped += 360 while $unwrapped - $target <= -180;

    return $unwrapped;
}

sub zodiac_sign_from_index {
    my ($index) = @_;

    my @signs = qw(Aries Taurus Gemini Cancer Leo Virgo Libra Scorpio Sagittarius Capricorn Aquarius Pisces);
    return $signs[mod_12($index)];
}

sub mod_12 {
    my ($value) = @_;
    my $mod = $value % 12;
    $mod += 12 if $mod < 0;
    return $mod;
}

sub normalize_360 {
    my ($angle) = @_;
    $angle -= 360 * floor($angle / 360);
    $angle += 360 if $angle < 0;
    return $angle;
}

sub format_jd_as_local_time {
    my ($jd) = @_;

    my $epoch = ($jd - 2440587.5) * 86400;
    my $whole = floor($epoch);
    my $fraction = $epoch - $whole;
    my $millis = int(($fraction * 1000) + 0.5);

    if ($millis >= 1000) {
        $millis = 0;
        $whole += 1;
    }

    my $tp = localtime($whole);
    return sprintf('%s.%03d', $tp->strftime('%Y-%m-%d %H:%M:%S'), $millis);
}

sub planet_definitions {
    return (
        { id => SE_SUN(),     label => 'Sun' },
        { id => SE_MERCURY(), label => 'Mercury' },
        { id => SE_VENUS(),   label => 'Venus' },
        { id => SE_MARS(),    label => 'Mars' },
        { id => SE_JUPITER(), label => 'Jupiter' },
        { id => SE_SATURN(),  label => 'Saturn' },
        { id => SE_URANUS(),  label => 'Uranus' },
        { id => SE_NEPTUNE(), label => 'Neptune' },
        { id => SE_PLUTO(),   label => 'Pluto' },
    );
}

sub require_swiss_eph {
    return if !$SWISS_EPH_LOAD_ERROR;

    die <<'ERROR';
SwissEph is not available on this system.

Install the SwissEph Perl module and, if needed, point --ephe-path at your ephemeris
files. Once that is available, rerun this script.
ERROR
}

sub usage {
    return <<'USAGE';
Usage:
  perl planet_ingress_display.pl --lat 47.3769 --lon 8.5417
  perl planet_ingress_display.pl --month 8 --year 2026 --lat 47.3769 --lon 8.5417
  perl planet_ingress_display.pl --month 8 --year 2026 --lat 47.3769 --lon 8.5417 \
    --house-system K --elev 408 --ephe-path /path/to/ephe

Options:
  --month         Target month number (defaults to the current local month)
  --year          Target four-digit year (defaults to the current local year)
  --lat           Latitude in decimal degrees
  --lon           Longitude in decimal degrees (east positive, west negative)
  --elev          Elevation in meters above sea level (defaults to 0)
  --house-system  SwissEph house system code (defaults to P / Placidus)
  --ephe-path     Ephemeris directory, or $SE_EPHE_PATH when set
  --help          Show this help text

Notes:
  The report scans the Sun and planets Mercury through Pluto.
  Date/time output is shown in the machine's local timezone.
  Sign ingress timing uses geocentric longitude.
  The House column is the house occupied at the exact ingress moment, computed
  topocentrically from the supplied location and house system.
USAGE
}
