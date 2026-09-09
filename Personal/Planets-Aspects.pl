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

our $SWISSEPH_LOAD_ERROR;
BEGIN {
    eval {
        require SwissEph;
        1;
    } or do {
        $SWISSEPH_LOAD_ERROR = $@ || 'Unable to load SwissEph';
    };
}

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

die swiss_eph_missing_message()
    if defined $SWISSEPH_LOAD_ERROR;

die "--month must be between 1 and 12\n"
    if $opt{month} < 1 || $opt{month} > 12;

die "--year must be a four-digit year\n"
    if $opt{year} < 1000 || $opt{year} > 9999;

if (defined $opt{ephe_path} && length $opt{ephe_path}) {
    SwissEph::swe_set_ephe_path($opt{ephe_path});
}

my ($start_epoch, $end_epoch) = month_bounds_epoch($opt{year}, $opt{month});
my $start_local = localtime($start_epoch);
my $start_utc = gmtime($start_epoch);
my $end_utc = gmtime($end_epoch);
my $start_jd = utc_to_jd($start_utc);
my $end_jd = utc_to_jd($end_utc);

my @events = find_planet_pair_aspects($start_jd, $end_jd, \%opt);

say sprintf('Planet Aspects for %s', $start_local->strftime('%B %Y'));
say 'Displayed in local time.';
say 'Planets: Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune, Pluto';
say 'Aspects: Conjunction, Sextile, Square, Trine, Opposition';
say 'Moon excluded.';
say 'Ephemeris mode: ' . ephemeris_mode_label(\%opt);
say '';
say sprintf(
    '%-9s  %-9s  %-12s  %-6s  %s',
    'Planet 1',
    'Planet 2',
    'Aspect',
    'Angle',
    'Local Time',
);
say '-' x 78;

for my $event (@events) {
    say sprintf(
        '%-9s  %-9s  %-12s  %-6s  %s',
        $event->{planet_1},
        $event->{planet_2},
        $event->{aspect},
        $event->{angle_label},
        format_jd_as_local($event->{jd}),
    );
}

say '(no major planet-to-planet aspects found in the requested month)'
    if !@events;

SwissEph::swe_close();

sub find_planet_pair_aspects {
    my ($start_jd, $end_jd, $opt) = @_;

    my @events;
    for my $pair (planet_pairs()) {
        push @events, find_pair_aspects($start_jd, $end_jd, $pair, $opt);
    }

    @events = sort {
        $a->{jd} <=> $b->{jd}
            || $a->{planet_1} cmp $b->{planet_1}
            || $a->{planet_2} cmp $b->{planet_2}
            || $a->{angle} <=> $b->{angle}
    } @events;

    my @unique;
    EVENT:
    for my $event (@events) {
        if (@unique) {
            my $last = $unique[-1];
            if (
                $event->{planet_1} eq $last->{planet_1}
                && $event->{planet_2} eq $last->{planet_2}
                && $event->{aspect} eq $last->{aspect}
                && abs($event->{jd} - $last->{jd}) < 1e-8
            ) {
                next EVENT;
            }
        }

        push @unique, $event;
    }

    return @unique;
}

sub find_pair_aspects {
    my ($start_jd, $end_jd, $pair, $opt) = @_;

    my @targets = aspect_targets();
    my $step_days = 1 / 24;
    my $prev_jd = $start_jd;
    my $prev_raw = planet_pair_angle($prev_jd, $pair->{id_1}, $pair->{id_2}, $opt);
    my $prev_unwrapped = $prev_raw;
    my $offset = 0;
    my @events;

    while ($prev_jd < $end_jd) {
        my $jd = $prev_jd + $step_days;
        $jd = $end_jd if $jd > $end_jd;

        my $raw = planet_pair_angle($jd, $pair->{id_1}, $pair->{id_2}, $opt);
        if ($raw < $prev_raw - 180) {
            $offset += 360;
        }
        elsif ($raw > $prev_raw + 180) {
            $offset -= 360;
        }

        my $unwrapped = unwrap_angle_near($raw + $offset, $prev_unwrapped);

        for my $target (@targets) {
            my @target_angles = target_crossings_between(
                $prev_unwrapped,
                $unwrapped,
                $target->{raw_angle},
            );

            for my $target_angle (@target_angles) {
                my $aspect_jd = refine_aspect_time(
                    $prev_jd,
                    $jd,
                    $pair,
                    $target_angle,
                    $opt,
                );

                if ($aspect_jd >= $start_jd && $aspect_jd < $end_jd) {
                    push @events, {
                        angle       => $target->{display_angle},
                        angle_label => sprintf('%d%s', $target->{display_angle}, chr(176)),
                        aspect      => $target->{name},
                        jd          => $aspect_jd,
                        planet_1    => $pair->{name_1},
                        planet_2    => $pair->{name_2},
                    };
                }
            }
        }

        $prev_jd = $jd;
        $prev_raw = $raw;
        $prev_unwrapped = $unwrapped;
    }

    return @events;
}

sub target_crossings_between {
    my ($from, $to, $base_angle) = @_;

    my ($min, $max) = $from <= $to ? ($from, $to) : ($to, $from);
    my $first_k = floor(($min - $base_angle) / 360);
    my $last_k = floor(($max - $base_angle) / 360);
    my @targets;

    for my $k ($first_k .. $last_k) {
        my $target = $base_angle + (360 * $k);
        next if $target < $min - 1e-12;
        next if $target > $max + 1e-12;
        push @targets, $target;
    }

    return @targets;
}

sub refine_aspect_time {
    my ($lo, $hi, $pair, $target_angle, $opt) = @_;

    my $flo = aspect_error($lo, $pair, $target_angle, $opt);
    my $fhi = aspect_error($hi, $pair, $target_angle, $opt);

    return $lo if abs($flo) < 1e-10;
    return $hi if abs($fhi) < 1e-10;

    my $jd = ($lo + $hi) / 2;

    for (1 .. 20) {
        my ($error, $speed) = aspect_error_and_speed($jd, $pair, $target_angle, $opt);
        return $jd if abs($error) < 1e-9;

        last if abs($speed) < 1e-9;

        my $next_jd = $jd - ($error / $speed);
        last if $next_jd <= $lo || $next_jd >= $hi;

        $jd = $next_jd;
    }

    for (1 .. 100) {
        my $mid = ($lo + $hi) / 2;
        my $fmid = aspect_error($mid, $pair, $target_angle, $opt);

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

sub planet_pair_angle {
    my ($jd, $planet_1_id, $planet_2_id, $opt) = @_;

    my $iflag = base_iflag($opt);
    my $planet_1 = SwissEph::swe_calc_ut($jd, $planet_1_id, $iflag);
    die "SwissEph planet calc failed: $planet_1->{serr}\n"
        if defined $planet_1->{serr} && length $planet_1->{serr};

    my $planet_2 = SwissEph::swe_calc_ut($jd, $planet_2_id, $iflag);
    die "SwissEph planet calc failed: $planet_2->{serr}\n"
        if defined $planet_2->{serr} && length $planet_2->{serr};

    return normalize_360($planet_1->{xx}->[0] - $planet_2->{xx}->[0]);
}

sub aspect_error {
    my ($jd, $pair, $target_angle, $opt) = @_;

    my $angle = unwrap_angle_near(
        planet_pair_angle($jd, $pair->{id_1}, $pair->{id_2}, $opt),
        $target_angle,
    );
    return $angle - $target_angle;
}

sub aspect_error_and_speed {
    my ($jd, $pair, $target_angle, $opt) = @_;

    my $iflag = base_iflag($opt) | swe_const('SEFLG_SPEED');
    my $planet_1 = SwissEph::swe_calc_ut($jd, $pair->{id_1}, $iflag);
    die "SwissEph planet calc failed: $planet_1->{serr}\n"
        if defined $planet_1->{serr} && length $planet_1->{serr};

    my $planet_2 = SwissEph::swe_calc_ut($jd, $pair->{id_2}, $iflag);
    die "SwissEph planet calc failed: $planet_2->{serr}\n"
        if defined $planet_2->{serr} && length $planet_2->{serr};

    my $angle = unwrap_angle_near(
        normalize_360($planet_1->{xx}->[0] - $planet_2->{xx}->[0]),
        $target_angle,
    );
    my $error = $angle - $target_angle;
    my $speed = $planet_1->{xx}->[3] - $planet_2->{xx}->[3];

    return ($error, $speed);
}

sub planet_pairs {
    my @planets = planet_bodies();
    my @pairs;

    for my $i (0 .. $#planets - 1) {
        for my $j ($i + 1 .. $#planets) {
            push @pairs, {
                id_1   => $planets[$i]->{id},
                id_2   => $planets[$j]->{id},
                name_1 => $planets[$i]->{name},
                name_2 => $planets[$j]->{name},
            };
        }
    }

    return @pairs;
}

sub planet_bodies {
    return (
        { id => swe_const('SE_MERCURY'), name => 'Mercury' },
        { id => swe_const('SE_VENUS'),   name => 'Venus'   },
        { id => swe_const('SE_MARS'),    name => 'Mars'    },
        { id => swe_const('SE_JUPITER'), name => 'Jupiter' },
        { id => swe_const('SE_SATURN'),  name => 'Saturn'  },
        { id => swe_const('SE_URANUS'),  name => 'Uranus'  },
        { id => swe_const('SE_NEPTUNE'), name => 'Neptune' },
        { id => swe_const('SE_PLUTO'),   name => 'Pluto'   },
    );
}

sub aspect_targets {
    return (
        { raw_angle =>   0, display_angle =>   0, name => 'Conjunction' },
        { raw_angle =>  60, display_angle =>  60, name => 'Sextile'     },
        { raw_angle =>  90, display_angle =>  90, name => 'Square'      },
        { raw_angle => 120, display_angle => 120, name => 'Trine'       },
        { raw_angle => 180, display_angle => 180, name => 'Opposition'  },
        { raw_angle => 240, display_angle => 120, name => 'Trine'       },
        { raw_angle => 270, display_angle =>  90, name => 'Square'      },
        { raw_angle => 300, display_angle =>  60, name => 'Sextile'     },
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

    my $jd = SwissEph::swe_utc_to_jd(
        $utc_time->year,
        $utc_time->mon,
        $utc_time->mday,
        $utc_time->hour,
        $utc_time->min,
        $utc_time->sec + 0,
        swe_const('SE_GREG_CAL'),
    );

    die "SwissEph UTC->JD failed: $jd->{serr}\n"
        if defined $jd->{serr} && length $jd->{serr};

    return $jd->{tjd_ut};
}

sub base_iflag {
    my ($opt) = @_;

    return swe_const('SEFLG_SWIEPH')
        if defined $opt->{ephe_path} && length $opt->{ephe_path};

    return swe_const('SEFLG_MOSEPH');
}

sub ephemeris_mode_label {
    my ($opt) = @_;

    return 'Swiss Ephemeris files (SEFLG_SWIEPH)'
        if defined $opt->{ephe_path} && length $opt->{ephe_path};

    return 'Moshier built-in ephemeris (SEFLG_MOSEPH)';
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

sub swe_const {
    my ($name) = @_;

    no strict 'refs';
    my $full_name = "SwissEph::$name";
    die "SwissEph constant $name is not available\n" unless defined &{$full_name};
    return &{$full_name}();
}

sub swiss_eph_missing_message {
    return <<'MESSAGE';
SwissEph could not be loaded in this workspace.

This script calculates major planet-to-planet aspects for one local calendar month.
The Moon is excluded.

Once the SwissEph Perl module is available, run:
  perl Planets-Aspects.pl

Optional:
  perl Planets-Aspects.pl --month 8 --year 2026
  perl Planets-Aspects.pl --ephe-path /path/to/ephe
MESSAGE
}

sub usage {
    return <<'USAGE';
Usage:
  perl Planets-Aspects.pl
  perl Planets-Aspects.pl --month 8 --year 2026
  perl Planets-Aspects.pl --month 8 --year 2026 --ephe-path /path/to/ephe

Print major aspects between Mercury, Venus, Mars, Jupiter, Saturn, Uranus,
Neptune, and Pluto for one local calendar month.

Notes:
  - The Moon is excluded.
  - Each planet pair is calculated once.
  - Times are displayed in the local system timezone.

Options:
  --month         Target month number (defaults to the current local month)
  --year          Target four-digit year (defaults to the current local year)
  --ephe-path     Optional Swiss Ephemeris path
  --debug         Reserved for troubleshooting
  --help, -h      Show this help text
USAGE
}
