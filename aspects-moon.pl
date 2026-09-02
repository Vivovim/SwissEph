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

my %opt = (
    debug     => 0,
    ephe_path => $ENV{SE_EPHE_PATH},
    month     => $now->mon,
    year      => $now->year,
);

GetOptions(
    'debug!'      => \$opt{debug},
    'ephe-path=s' => \$opt{ephe_path},
    'help|h'      => \$opt{help},
    'month=i'     => \$opt{month},
    'year=i'      => \$opt{year},
) or die usage();

if ($opt{help}) {
    print usage();
    exit 0;
}

die "--month must be between 1 and 12\n"
    if $opt{month} < 1 || $opt{month} > 12;

die "--year must be a four-digit year\n"
    if $opt{year} < 1000 || $opt{year} > 9999;

if (defined $opt{ephe_path} && length $opt{ephe_path}) {
    swe_set_ephe_path($opt{ephe_path});
}

my ($start_epoch, $end_epoch) = month_bounds_epoch($opt{year}, $opt{month});
my $start_local = localtime($start_epoch);
my $start_utc = gmtime($start_epoch);
my $end_utc = gmtime($end_epoch);
my $start_jd = utc_to_jd($start_utc);
my $end_jd = utc_to_jd($end_utc);

my @events = find_moon_aspects($start_jd, $end_jd, \%opt);

say sprintf('Moon Aspects for %s', $start_local->strftime('%B %Y'));
say 'Displayed in local time.';
say 'Planets: Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune, Pluto';
say 'Aspects: Conjunction, Sextile, Square, Trine, Opposition';
say 'Ephemeris mode: ' . ephemeris_mode_label(\%opt);
say '';
say sprintf(
    '%-8s  %-9s  %-12s  %-6s  %s',
    'Moon',
    'Planet',
    'Aspect',
    'Angle',
    'Local Time',
);
say '-' x 76;

for my $event (@events) {
    say sprintf(
        '%-8s  %-9s  %-12s  %-6s  %s',
        'Moon',
        $event->{planet},
        $event->{aspect},
        $event->{angle_label},
        format_jd_as_local($event->{jd}),
    );
}

say '(no Moon major aspects found in the requested month)'
    if !@events;

swe_close();

sub find_moon_aspects {
    my ($start_jd, $end_jd, $opt) = @_;

    my @events;
    for my $planet (planet_bodies()) {
        push @events, find_planet_aspects($start_jd, $end_jd, $planet, $opt);
    }

    return sort {
        $a->{jd} <=> $b->{jd}
            || $a->{planet} cmp $b->{planet}
            || $a->{angle} <=> $b->{angle}
    } @events;
}

sub find_planet_aspects {
    my ($start_jd, $end_jd, $planet, $opt) = @_;

    my @targets = aspect_targets();
    my %next_target_abs;

    my $step_days = 1 / 96;
    my $prev_jd = $start_jd;
    my $prev_raw = moon_planet_angle($prev_jd, $planet->{id}, $opt);
    my $prev_unwrapped = $prev_raw;
    my $offset = 0;
    my @events;

    for my $target (@targets) {
        my $target_abs = $target->{angle};
        $target_abs += 360 while $target_abs < ($prev_unwrapped - 1e-7);
        $next_target_abs{$target->{angle}} = $target_abs;
    }

    while ($prev_jd < $end_jd) {
        my $jd = $prev_jd + $step_days;
        $jd = $end_jd if $jd > $end_jd;

        my $raw = moon_planet_angle($jd, $planet->{id}, $opt);
        if ($raw < $prev_raw - 180) {
            $offset += 360;
        }
        elsif ($raw > $prev_raw + 180) {
            $offset -= 360;
        }

        my $unwrapped = $raw + $offset;
        $unwrapped = unwrap_angle_near($unwrapped, $prev_unwrapped);

        for my $target (@targets) {
            my $base_angle = $target->{angle};

            while (
                $next_target_abs{$base_angle} >= ($prev_unwrapped - 1e-12)
                    && $next_target_abs{$base_angle} <= $unwrapped
            ) {
                my $aspect_jd = refine_aspect_time(
                    $prev_jd,
                    $jd,
                    $planet->{id},
                    $next_target_abs{$base_angle},
                    $opt,
                );

                if ($aspect_jd >= $start_jd && $aspect_jd < $end_jd) {
                    push @events, {
                        angle       => $base_angle,
                        angle_label => sprintf('%d%s', $base_angle, chr(176)),
                        aspect      => $target->{name},
                        jd          => $aspect_jd,
                        planet      => $planet->{name},
                    };
                }

                $next_target_abs{$base_angle} += 360;
            }
        }

        $prev_jd = $jd;
        $prev_raw = $raw;
        $prev_unwrapped = $unwrapped;
    }

    return @events;
}

sub refine_aspect_time {
    my ($lo, $hi, $planet_id, $target_angle, $opt) = @_;

    my $flo = aspect_error($lo, $planet_id, $target_angle, $opt);
    my $fhi = aspect_error($hi, $planet_id, $target_angle, $opt);

    return $lo if abs($flo) < 1e-10;
    return $hi if abs($fhi) < 1e-10;

    my $jd = ($lo + $hi) / 2;

    for (1 .. 20) {
        my ($error, $speed) = aspect_error_and_speed($jd, $planet_id, $target_angle, $opt);
        return $jd if abs($error) < 1e-9;

        last if abs($speed) < 1e-9;

        my $next_jd = $jd - ($error / $speed);
        last if $next_jd <= $lo || $next_jd >= $hi;

        $jd = $next_jd;
    }

    for (1 .. 100) {
        my $mid = ($lo + $hi) / 2;
        my $fmid = aspect_error($mid, $planet_id, $target_angle, $opt);

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

sub moon_planet_angle {
    my ($jd, $planet_id, $opt) = @_;

    my $iflag = base_iflag($opt);
    my $moon = swe_calc_ut($jd, SE_MOON, $iflag);
    die "SwissEph moon calc failed: $moon->{serr}\n"
        if defined $moon->{serr} && length $moon->{serr};

    my $planet = swe_calc_ut($jd, $planet_id, $iflag);
    die "SwissEph planet calc failed: $planet->{serr}\n"
        if defined $planet->{serr} && length $planet->{serr};

    return normalize_360($moon->{xx}->[0] - $planet->{xx}->[0]);
}

sub aspect_error {
    my ($jd, $planet_id, $target_angle, $opt) = @_;

    my $angle = unwrap_angle_near(moon_planet_angle($jd, $planet_id, $opt), $target_angle);
    return $angle - $target_angle;
}

sub aspect_error_and_speed {
    my ($jd, $planet_id, $target_angle, $opt) = @_;

    my $iflag = base_iflag($opt) | SEFLG_SPEED;
    my $moon = swe_calc_ut($jd, SE_MOON, $iflag);
    die "SwissEph moon calc failed: $moon->{serr}\n"
        if defined $moon->{serr} && length $moon->{serr};

    my $planet = swe_calc_ut($jd, $planet_id, $iflag);
    die "SwissEph planet calc failed: $planet->{serr}\n"
        if defined $planet->{serr} && length $planet->{serr};

    my $angle = unwrap_angle_near(
        normalize_360($moon->{xx}->[0] - $planet->{xx}->[0]),
        $target_angle,
    );
    my $error = $angle - $target_angle;
    my $speed = $moon->{xx}->[3] - $planet->{xx}->[3];

    return ($error, $speed);
}

sub planet_bodies {
    return (
        { id => SE_MERCURY(), name => 'Mercury' },
        { id => SE_VENUS(),   name => 'Venus'   },
        { id => SE_MARS(),    name => 'Mars'    },
        { id => SE_JUPITER(), name => 'Jupiter' },
        { id => SE_SATURN(),  name => 'Saturn'  },
        { id => SE_URANUS(),  name => 'Uranus'  },
        { id => SE_NEPTUNE(), name => 'Neptune' },
        { id => SE_PLUTO(),   name => 'Pluto'   },
    );
}

sub aspect_targets {
    return (
        { angle =>   0, name => 'Conjunction' },
        { angle =>  60, name => 'Sextile'     },
        { angle =>  90, name => 'Square'      },
        { angle => 120, name => 'Trine'       },
        { angle => 180, name => 'Opposition'  },
        { angle => 240, name => 'Trine'       },
        { angle => 270, name => 'Square'      },
        { angle => 300, name => 'Sextile'     },
    );
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

sub unwrap_angle_near {
    my ($angle, $reference) = @_;

    my $unwrapped = $angle;
    $unwrapped -= 360 while $unwrapped - $reference > 180;
    $unwrapped += 360 while $unwrapped - $reference <= -180;

    return $unwrapped;
}

sub normalize_360 {
    my ($angle) = @_;
    $angle -= 360 * floor($angle / 360);
    $angle += 360 if $angle < 0;
    return $angle;
}

sub format_jd_as_local {
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
    return sprintf('%s.%03d', $tp->strftime('%Y-%m-%d %H:%M:%S %Z %z'), $millis);
}

sub usage {
    return <<'USAGE';
Usage:
  perl aspects-moon.pl
  perl aspects-moon.pl --month 8 --year 2026
  perl aspects-moon.pl --month 8 --year 2026 --ephe-path /path/to/ephemeris

Print the Moon's major aspects to Mercury, Venus, Mars, Jupiter, Saturn,
Uranus, Neptune, and Pluto for one local calendar month.

Options:
  --month         Target month number (defaults to the current local month)
  --year          Target four-digit year (defaults to the current local year)
  --ephe-path     Optional Swiss Ephemeris path
  --debug         Reserved for troubleshooting
  --help, -h      Show this help text
USAGE
}
