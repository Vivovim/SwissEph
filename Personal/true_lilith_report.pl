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

our $SWISSEPH_LOAD_ERROR;
BEGIN {
    eval {
        require SwissEph;
        1;
    } or do {
        $SWISSEPH_LOAD_ERROR = $@ || 'Unable to load SwissEph';
    };
}

my $LOCAL_TZ = 'America/Phoenix';
set_timezone($LOCAL_TZ);
my $now = time;

my %opt = (
    datetime  => undef,
    ephe_path => $ENV{SE_EPHE_PATH},
    help      => 0,
    orb       => 3,
);

GetOptions(
    'datetime=s'  => \$opt{datetime},
    'ephe-path=s' => \$opt{ephe_path},
    'help|h'      => \$opt{help},
    'orb=f'       => \$opt{orb},
) or die usage();

if ($opt{help}) {
    print usage();
    exit 0;
}

die swiss_eph_missing_message()
    if defined $SWISSEPH_LOAD_ERROR;

die "--orb must be between 0 and 15 degrees\n"
    if !defined $opt{orb} || $opt{orb} < 0 || $opt{orb} > 15;

if (defined $opt{ephe_path} && length $opt{ephe_path}) {
    SwissEph::swe_set_ephe_path($opt{ephe_path});
}

my $timestamp_local = parse_datetime($opt{datetime}, $now);
my $timestamp_utc = gmtime($timestamp_local->epoch);
my $jd = utc_to_jd($timestamp_utc);
my $iflag = base_iflag(\%opt);

my $lilith = SwissEph::swe_calc_ut(
    $jd,
    swe_const('SE_OSCU_APOG'),
    $iflag | swe_const('SEFLG_SPEED'),
);
die "SwissEph True Lilith calc failed: $lilith->{serr}\n"
    if defined $lilith->{serr} && length $lilith->{serr};

my $lilith_longitude = normalize_360($lilith->{xx}->[0]);
my $lilith_sign = zodiac_sign($lilith_longitude);
my $lilith_motion = ($lilith->{xx}->[3] // 0) < 0 ? 'Retrograde' : 'Direct';
my @aspects = current_aspects($jd, $lilith_longitude, \%opt);
my $next_ingress = next_sign_ingress($jd, \%opt);

say "Timestamp ($LOCAL_TZ): " . $timestamp_local->strftime('%Y-%m-%d %H:%M:%S');
say 'Timestamp (UTC): ' . $timestamp_utc->strftime('%Y-%m-%d %H:%M:%S');
say 'Body: True Lilith (oscillating lunar apogee)';
say 'Ephemeris mode: ' . ephemeris_mode_label(\%opt);
say '';
say 'Primary Report';
say '--------------';
say 'Zodiac longitude: ' . format_longitude($lilith_longitude);
say "Current sign: $lilith_sign";
say "Motion: $lilith_motion";
say '';
say sprintf('Aspects to planets (orb %.2f%s)', $opt{orb}, chr(176));
say '--------------------------------';

if (@aspects) {
    say sprintf('%-10s  %-12s  %-12s  %s', 'Planet', 'Aspect', 'Orb', 'Longitude');
    say '-' x 56;

    for my $aspect (@aspects) {
        say sprintf(
            '%-10s  %-12s  %-12s  %s',
            $aspect->{planet},
            $aspect->{aspect},
            format_angle($aspect->{orb}),
            format_longitude($aspect->{longitude}),
        );
    }
}
else {
    say sprintf('(no major aspects within %.2f%s)', $opt{orb}, chr(176));
}

say '';
say 'Secondary Display';
say '-----------------';

if ($next_ingress) {
    say 'Next sign ingress: '
        . format_jd_as_local_time($next_ingress->{jd})
        . ' -> '
        . $next_ingress->{sign};
}
else {
    say '(next sign ingress not found within the search window)';
}

SwissEph::swe_close();

sub current_aspects {
    my ($jd, $lilith_longitude, $opt) = @_;

    my @matches;
    my $iflag = base_iflag($opt);

    for my $planet (planet_definitions()) {
        my $calc = SwissEph::swe_calc_ut($jd, $planet->{id}, $iflag);
        die "SwissEph planet calc failed for $planet->{name}: $calc->{serr}\n"
            if defined $calc->{serr} && length $calc->{serr};

        my $longitude = normalize_360($calc->{xx}->[0]);
        my $aspect = nearest_aspect(normalize_360($lilith_longitude - $longitude));
        next if $aspect->{orb} > $opt->{orb};

        push @matches, {
            aspect    => $aspect->{name},
            longitude => $longitude,
            orb       => $aspect->{orb},
            planet    => $planet->{name},
        };
    }

    return sort {
        $a->{orb} <=> $b->{orb}
            ||
        $a->{planet} cmp $b->{planet}
    } @matches;
}

sub nearest_aspect {
    my ($angle) = @_;

    my @targets = (
        { angle =>   0, name => 'Conjunction' },
        { angle =>  60, name => 'Sextile'     },
        { angle =>  90, name => 'Square'      },
        { angle => 120, name => 'Trine'       },
        { angle => 180, name => 'Opposition'  },
        { angle => 240, name => 'Trine'       },
        { angle => 270, name => 'Square'      },
        { angle => 300, name => 'Sextile'     },
    );

    my $best;
    for my $target (@targets) {
        my $orb = abs(unwrap_angle_near($angle, $target->{angle}) - $target->{angle});
        if (!$best || $orb < $best->{orb}) {
            $best = {
                angle => $target->{angle},
                name  => $target->{name},
                orb   => $orb,
            };
        }
    }

    return $best;
}

sub next_sign_ingress {
    my ($start_jd, $opt) = @_;

    my $step_days = 1 / 12;
    my $max_days = 400;
    my $prev_jd = $start_jd;
    my $prev_sign_index = sign_index(lilith_longitude_at($prev_jd, $opt));
    my $max_steps = int($max_days / $step_days);

    for my $step (1 .. $max_steps) {
        my $jd = $start_jd + ($step * $step_days);
        my $sign_index = sign_index(lilith_longitude_at($jd, $opt));
        next if $sign_index == $prev_sign_index;

        my $ingress_jd = refine_sign_change($prev_jd, $jd, $prev_sign_index, $opt);
        my $new_sign_index = sign_index(lilith_longitude_at($ingress_jd + (1 / 86400), $opt));

        return {
            jd   => $ingress_jd,
            sign => zodiac_sign_from_index($new_sign_index),
        };
    }

    return;
}

sub refine_sign_change {
    my ($lo, $hi, $from_sign_index, $opt) = @_;

    for (1 .. 100) {
        my $mid = ($lo + $hi) / 2;
        my $mid_sign_index = sign_index(lilith_longitude_at($mid, $opt));

        if ($mid_sign_index == $from_sign_index) {
            $lo = $mid;
        }
        else {
            $hi = $mid;
        }

        last if ($hi - $lo) * 86400 < 0.25;
    }

    return ($lo + $hi) / 2;
}

sub lilith_longitude_at {
    my ($jd, $opt) = @_;

    my $calc = SwissEph::swe_calc_ut($jd, swe_const('SE_OSCU_APOG'), base_iflag($opt));
    die "SwissEph True Lilith calc failed: $calc->{serr}\n"
        if defined $calc->{serr} && length $calc->{serr};

    return normalize_360($calc->{xx}->[0]);
}

sub planet_definitions {
    return (
        { id => swe_const('SE_SUN'),     name => 'Sun'     },
        { id => swe_const('SE_MOON'),    name => 'Moon'    },
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

    return 'SwissEph with Moshier built-in ephemeris (SEFLG_MOSEPH)';
}

sub sign_index {
    my ($longitude) = @_;
    return int(normalize_360($longitude) / 30);
}

sub zodiac_sign {
    my ($longitude) = @_;
    return zodiac_sign_from_index(sign_index($longitude));
}

sub zodiac_sign_from_index {
    my ($index) = @_;

    my @signs = qw(
        Aries Taurus Gemini Cancer Leo Virgo
        Libra Scorpio Sagittarius Capricorn Aquarius Pisces
    );

    return $signs[$index % 12];
}

sub format_longitude {
    my ($longitude) = @_;

    my $normalized = normalize_360($longitude);
    my $sign_index = int($normalized / 30);
    my $within_sign = $normalized - ($sign_index * 30);
    my $degrees = int($within_sign);
    my $minutes_full = ($within_sign - $degrees) * 60;
    my $minutes = int($minutes_full);
    my $seconds = ($minutes_full - $minutes) * 60;

    return sprintf(
        '%02d %s %02d\' %05.2f"',
        $degrees,
        zodiac_sign_from_index($sign_index),
        $minutes,
        $seconds,
    );
}

sub format_angle {
    my ($angle) = @_;

    my $degrees = int($angle);
    my $minutes_full = ($angle - $degrees) * 60;
    my $minutes = int($minutes_full);
    my $seconds = ($minutes_full - $minutes) * 60;

    return sprintf('%d%s %02d\' %05.2f"', $degrees, chr(176), $minutes, $seconds);
}

sub normalize_360 {
    my ($angle) = @_;

    $angle -= 360 * floor($angle / 360);
    $angle += 360 if $angle < 0;

    return $angle;
}

sub unwrap_angle_near {
    my ($angle, $reference) = @_;

    my $unwrapped = $angle;
    $unwrapped -= 360 while $unwrapped - $reference > 180;
    $unwrapped += 360 while $unwrapped - $reference <= -180;

    return $unwrapped;
}

sub parse_datetime {
    my ($input, $epoch_now) = @_;

    return localtime($epoch_now) unless defined $input && length $input;

    my $normalized = normalize_datetime($input);
    my ($year, $month, $day, $hour, $minute, $second, $is_utc) =
        $normalized =~ /\A(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(Z?)\z/
        or die "Unsupported datetime format. Use 2026-08-12T14:30:00 or 2026-08-12T21:30:00Z\n";

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
    return sprintf('%s.%03d', $tp->strftime('%Y-%m-%d %H:%M:%S %Z %z'), $millis);
}

sub swe_const {
    my ($name) = @_;

    no strict 'refs';
    my $full_name = "SwissEph::$name";
    die "SwissEph constant $name is not available\n" unless defined &{$full_name};
    return &{$full_name}();
}

sub set_timezone {
    my ($tz) = @_;
    $ENV{TZ} = $tz;
    tzset();
}

sub swiss_eph_missing_message {
    return <<'MESSAGE';
SwissEph could not be loaded in this workspace.

This script reports True Lilith (oscillating lunar apogee), its zodiac longitude,
its current sign, current aspects to planets, and the next sign ingress.

Once the SwissEph Perl module is available, run:
  perl true_lilith_report.pl

Optional:
  perl true_lilith_report.pl --datetime 2026-08-20T14:30:00
  perl true_lilith_report.pl --datetime 2026-08-20T21:30:00Z
  perl true_lilith_report.pl --ephe-path /path/to/ephe
MESSAGE
}

sub usage {
    return <<'USAGE';
Usage:
  perl true_lilith_report.pl
  perl true_lilith_report.pl --datetime 2026-08-20T14:30:00
  perl true_lilith_report.pl --datetime 2026-08-20T21:30:00Z
  perl true_lilith_report.pl --orb 3
  perl true_lilith_report.pl --ephe-path /path/to/ephe

Notes:
  --datetime defaults to the current America/Phoenix local time if omitted.
  --datetime without a timezone is interpreted as America/Phoenix.
  --datetime with a trailing Z is interpreted as UTC.
  --orb defaults to 3 degrees.
  --ephe-path defaults to $SE_EPHE_PATH when set.

Details:
  - True Lilith is calculated with Swiss Ephemeris body SE_OSCU_APOG.
  - The aspect list checks Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn,
    Uranus, Neptune, and Pluto.
  - The secondary display shows the next sign ingress after the requested time.
USAGE
}
