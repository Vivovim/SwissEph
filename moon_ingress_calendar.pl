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

use SwissEph qw(:all);

my $HAS_SWIEPH = eval { my $flag = SEFLG_SWIEPH; defined $flag } ? 1 : 0;
my $now = localtime(time);
my $LOCAL_TIME_LABEL = localtime(time)->strftime('%Z %z') || 'local time';

my %opt = (
    debug         => 0,
    elev         => 0,
    ephe_path    => $ENV{SE_EPHE_PATH},
    house_system => 'P',
    month        => $now->mon,
    topocentric_ingress => 0,
    year         => $now->year,
);

GetOptions(
    'debug!'         => \$opt{debug},
    'ephe-path=s'    => \$opt{ephe_path},
    'help|h'         => \$opt{help},
    'house-system=s' => \$opt{house_system},
    'lat=f'          => \$opt{lat},
    'lon=f'          => \$opt{lon},
    'elev=f'         => \$opt{elev},
    'month=i'        => \$opt{month},
    'topocentric-ingress!' => \$opt{topocentric_ingress},
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

my @events = find_moon_ingresses($start_jd, $end_jd, \%opt);

say sprintf('Moon Ingress Calendar for %s', $start_local->strftime('%B %Y'));
say sprintf(
    'Location: lat %.6f, lon %.6f, elev %.1f m',
    $opt{lat},
    $opt{lon},
    $opt{elev},
);
say 'House system: ' . swe_house_name($opt{house_system}) . " ($opt{house_system})";
say 'Moon longitude mode: ' . ($opt{topocentric_ingress} ? 'topocentric' : 'geocentric');
say 'Ephemeris mode: ' . ephemeris_mode_label(\%opt);
say '';
say sprintf(
    '%-12s  %-23s  %-23s  %-5s',
    'Moon Sign',
    "Local ($LOCAL_TIME_LABEL)",
    'UTC',
    'House',
);
say '-' x 72;

for my $event (@events) {
    say sprintf(
        '%-12s  %-23s  %-23s  %5d',
        $event->{sign},
        format_jd_as_time($event->{jd}, 0),
        format_jd_as_time($event->{jd}, 1),
        $event->{house},
    );
}

say '(no ingresses found in the requested month)'
    if !@events;

swe_close();

sub find_moon_ingresses {
    my ($start_jd, $end_jd, $opt) = @_;

    my $start_longitude = ingress_longitude($start_jd, $opt);
    my $next_boundary = (int($start_longitude / 30) + 1) * 30;
    my $search_start_jd = $start_jd;
    my @events;

    while ($search_start_jd < $end_jd) {
        my $ingress_jd = next_ingress_time($search_start_jd, $next_boundary, $end_jd, $opt);
        last if !defined $ingress_jd || $ingress_jd >= $end_jd;

        push @events, build_event($ingress_jd, $next_boundary, $opt);
        $search_start_jd = $ingress_jd + (1 / 86400 / 1000);
        $next_boundary += 30;
    }

    return @events;
}

sub build_event {
    my ($jd, $boundary_abs, $opt) = @_;

    my $target_sign_index = (int($boundary_abs / 30)) % 12;

    return {
        house      => moon_house($jd, $opt),
        jd         => $jd,
        sign       => zodiac_sign_from_index($target_sign_index),
    };
}

sub refine_ingress_time {
    my ($lo, $hi, $boundary_abs, $opt) = @_;

    my $flo = longitude_error($lo, $boundary_abs, $opt);
    my $fhi = longitude_error($hi, $boundary_abs, $opt);

    return $lo if abs($flo) < 1e-10;
    return $hi if abs($fhi) < 1e-10;

    my $jd = ($lo + $hi) / 2;

    for (1 .. 20) {
        my ($error, $speed) = longitude_error_and_speed($jd, $boundary_abs, $opt);
        return $jd if abs($error) < 1e-9;

        last if abs($speed) < 1e-9;

        my $next_jd = $jd - ($error / $speed);
        last if $next_jd <= $lo || $next_jd >= $hi;

        $jd = $next_jd;
    }

    for (1 .. 100) {
        my $mid = ($lo + $hi) / 2;
        my $fmid = longitude_error($mid, $boundary_abs, $opt);

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

sub next_ingress_time {
    my ($start_jd, $boundary_abs, $end_jd, $opt) = @_;

    if (!$opt->{topocentric_ingress} && SwissEph->can('swe_mooncross_ut')) {
        my $jd = eval { swe_mooncross_ut(normalize_360($boundary_abs), $start_jd, base_iflag($opt)) };
        if (!$@ && defined $jd && $jd >= $start_jd && $jd < $end_jd) {
            my $error = abs(longitude_error($jd, $boundary_abs, $opt));
            if ($error < 1e-6) {
                return $jd;
            }

            warn sprintf(
                "Discarding swe_mooncross_ut result for %.6f deg; residual was %.9f deg\n",
                normalize_360($boundary_abs),
                $error,
            ) if $opt->{debug};
        }
        elsif ($opt->{debug}) {
            my $message = $@ || 'crossing was outside the requested range';
            chomp $message;
            warn "Discarding swe_mooncross_ut result: $message\n";
        }
    }

    return next_ingress_time_fallback($start_jd, $boundary_abs, $end_jd, $opt);
}

sub next_ingress_time_fallback {
    my ($start_jd, $boundary_abs, $end_jd, $opt) = @_;

    my $step_days = 1 / 96;
    my $prev_jd = $start_jd;
    my $prev_raw = ingress_longitude($prev_jd, $opt);
    my $offset = int($boundary_abs / 360) * 360;
    my $prev_unwrapped = unwrap_longitude_near($prev_raw, $boundary_abs);

    while ($prev_jd < $end_jd) {
        my $jd = $prev_jd + $step_days;
        $jd = $end_jd if $jd > $end_jd;

        my $raw = ingress_longitude($jd, $opt);
        if ($raw < $prev_raw - 180) {
            $offset += 360;
        }
        elsif ($raw > $prev_raw + 180) {
            $offset -= 360;
        }

        my $unwrapped = $raw + $offset;
        $unwrapped = unwrap_longitude_near($unwrapped, $prev_unwrapped);

        if ($prev_unwrapped <= $boundary_abs && $unwrapped >= $boundary_abs) {
            return refine_ingress_time($prev_jd, $jd, $boundary_abs, $opt);
        }

        $prev_jd = $jd;
        $prev_raw = $raw;
        $prev_unwrapped = $unwrapped;
    }

    return undef;
}

sub ingress_longitude {
    my ($jd, $opt) = @_;

    my $moon = swe_calc_ut($jd, SE_MOON, ingress_iflag($opt));
    die "SwissEph moon calc failed: $moon->{serr}\n"
        if defined $moon->{serr} && length $moon->{serr};

    return normalize_360($moon->{xx}->[0]);
}

sub moon_house {
    my ($jd, $opt) = @_;

    my $iflag = moon_iflag($opt);
    my $houses = swe_houses_ex(
        $jd,
        $iflag,
        $opt->{lat},
        $opt->{lon},
        $opt->{house_system},
    );
    die "SwissEph houses failed: $houses->{serr}\n"
        if defined $houses->{serr} && length $houses->{serr};

    my $ecl_nut = swe_calc_ut($jd, SE_ECL_NUT, base_iflag($opt));
    die "SwissEph obliquity failed: $ecl_nut->{serr}\n"
        if defined $ecl_nut->{serr} && length $ecl_nut->{serr};

    my $moon = swe_calc_ut($jd, SE_MOON, $iflag);
    die "SwissEph moon calc failed: $moon->{serr}\n"
        if defined $moon->{serr} && length $moon->{serr};

    my ($longitude, $latitude) = @{ $moon->{xx} }[0, 1];
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
    my ($jd, $boundary_abs, $opt) = @_;

    my $longitude = unwrap_longitude_near(ingress_longitude($jd, $opt), $boundary_abs);
    return $longitude - $boundary_abs;
}

sub longitude_error_and_speed {
    my ($jd, $boundary_abs, $opt) = @_;

    my $moon = swe_calc_ut($jd, SE_MOON, ingress_iflag($opt) | SEFLG_SPEED);
    die "SwissEph moon calc failed: $moon->{serr}\n"
        if defined $moon->{serr} && length $moon->{serr};

    my $longitude = unwrap_longitude_near(normalize_360($moon->{xx}->[0]), $boundary_abs);
    my $error = $longitude - $boundary_abs;
    my $speed = $moon->{xx}->[3];

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
        SE_GREG_CAL,
    );

    die "SwissEph UTC->JD failed: $jd->{serr}\n"
        if defined $jd->{serr} && length $jd->{serr};

    return $jd->{tjd_ut};
}

sub moon_iflag {
    my ($opt) = @_;
    return base_iflag($opt) | SEFLG_TOPOCTR;
}

sub ingress_iflag {
    my ($opt) = @_;

    my $iflag = base_iflag($opt);
    $iflag |= SEFLG_TOPOCTR if $opt->{topocentric_ingress};

    return $iflag;
}

sub base_iflag {
    my ($opt) = @_;
    return SEFLG_SWIEPH if $HAS_SWIEPH && defined $opt->{ephe_path} && length $opt->{ephe_path};
    return SEFLG_MOSEPH;
}

sub ephemeris_mode_label {
    my ($opt) = @_;
    return 'Swiss Ephemeris (SEFLG_SWIEPH)' if base_iflag($opt) != SEFLG_MOSEPH;
    return 'Moshier fallback (SEFLG_MOSEPH)';
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
    return $signs[$index % 12];
}

sub normalize_360 {
    my ($angle) = @_;
    $angle -= 360 * floor($angle / 360);
    $angle += 360 if $angle < 0;
    return $angle;
}

sub format_jd_as_time {
    my ($jd, $is_utc) = @_;

    my $epoch = ($jd - 2440587.5) * 86400;
    my $whole = floor($epoch);
    my $fraction = $epoch - $whole;
    my $millis = int(($fraction * 1000) + 0.5);

    if ($millis >= 1000) {
        $millis = 0;
        $whole += 1;
    }

    my $tp = $is_utc ? gmtime($whole) : localtime($whole);
    return sprintf('%s.%03d', $tp->strftime('%Y-%m-%d %H:%M:%S'), $millis);
}

sub usage {
    return <<'USAGE';
Usage:
  perl moon_ingress_calendar.pl --lat 47.3769 --lon 8.5417 --elev 408
  perl moon_ingress_calendar.pl --month 8 --year 2026 --lat 47.3769 --lon 8.5417 --elev 408

Options:
  --month         Target month number (defaults to the current local month)
  --year          Target four-digit year (defaults to the current local year)
  --lat           Latitude in decimal degrees
  --lon           Longitude in decimal degrees (east positive, west negative)
  --elev          Elevation in meters above sea level (defaults to 0)
  --topocentric-ingress
                  Use topocentric Moon longitude for ingress timing
  --house-system  SwissEph house system code (defaults to P / Placidus)
  --ephe-path     Ephemeris directory, or $SE_EPHE_PATH when set
  --help          Show this help text

Notes:
  By default, ingress timing uses geocentric Moon longitude and house placement
  uses the supplied location. Use --topocentric-ingress if you want the ingress
  itself timed from a topocentric perspective.
USAGE
}
