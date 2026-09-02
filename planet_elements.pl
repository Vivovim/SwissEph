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
);

GetOptions(
    'datetime=s'  => \$opt{datetime},
    'ephe-path=s' => \$opt{ephe_path},
    'help|h'      => \$opt{help},
) or die usage();

if ($opt{help}) {
    print usage();
    exit 0;
}

die swiss_eph_missing_message()
    if defined $SWISSEPH_LOAD_ERROR;

if (defined $opt{ephe_path} && length $opt{ephe_path}) {
    SwissEph::swe_set_ephe_path($opt{ephe_path});
}

my $timestamp_local = parse_datetime($opt{datetime}, $now);
my $timestamp_utc = gmtime($timestamp_local->epoch);
my $jd = utc_to_jd($timestamp_utc);
my $iflag = base_iflag(\%opt);

my %elements = map { $_ => [] } qw(Fire Earth Air Water);

for my $planet (planet_definitions()) {
    my $calc = SwissEph::swe_calc_ut($jd, swe_const($planet->{const}), $iflag);
    die "SwissEph planet calc failed for $planet->{label}: $calc->{serr}\n"
        if defined $calc->{serr} && length $calc->{serr};

    my $longitude = $calc->{xx}->[0];
    my $sign = zodiac_sign($longitude);
    my $element = zodiac_element($sign);

    push @{ $elements{$element} }, sprintf('%s (%s)', $planet->{label}, $sign);
}

say "Timestamp ($LOCAL_TZ): " . $timestamp_local->strftime('%Y-%m-%d %H:%M:%S');
say 'Timestamp (UTC): ' . $timestamp_utc->strftime('%Y-%m-%d %H:%M:%S');
say 'Ephemeris mode: ' . ephemeris_mode_label(\%opt);
say '';

for my $element (qw(Fire Earth Air Water)) {
    my $members = @{ $elements{$element} }
        ? join(', ', @{ $elements{$element} })
        : '(none)';

    say "$element: $members";
}

SwissEph::swe_close();

sub planet_definitions {
    return (
        { const => 'SE_SUN',     label => 'Sun'     },
        { const => 'SE_MOON',    label => 'Moon'    },
        { const => 'SE_MERCURY', label => 'Mercury' },
        { const => 'SE_VENUS',   label => 'Venus'   },
        { const => 'SE_MARS',    label => 'Mars'    },
        { const => 'SE_JUPITER', label => 'Jupiter' },
        { const => 'SE_SATURN',  label => 'Saturn'  },
        { const => 'SE_URANUS',  label => 'Uranus'  },
        { const => 'SE_NEPTUNE', label => 'Neptune' },
        { const => 'SE_PLUTO',   label => 'Pluto'   },
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

    return 'Moshier built-in ephemeris (SEFLG_MOSEPH)';
}

sub zodiac_sign {
    my ($longitude) = @_;

    my @signs = qw(
        Aries Taurus Gemini Cancer Leo Virgo
        Libra Scorpio Sagittarius Capricorn Aquarius Pisces
    );

    my $normalized = normalize_360($longitude);
    my $sign_index = int($normalized / 30);

    return $signs[$sign_index];
}

sub zodiac_element {
    my ($sign) = @_;

    my %sign_to_element = (
        Aries       => 'Fire',
        Leo         => 'Fire',
        Sagittarius => 'Fire',
        Taurus      => 'Earth',
        Virgo       => 'Earth',
        Capricorn   => 'Earth',
        Gemini      => 'Air',
        Libra       => 'Air',
        Aquarius    => 'Air',
        Cancer      => 'Water',
        Scorpio     => 'Water',
        Pisces      => 'Water',
    );

    die "Unknown zodiac sign: $sign\n" unless exists $sign_to_element{$sign};

    return $sign_to_element{$sign};
}

sub normalize_360 {
    my ($angle) = @_;

    $angle -= 360 * floor($angle / 360);
    $angle += 360 if $angle < 0;

    return $angle;
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

This script groups planets by zodiac element using the Swiss Ephemeris Perl module.

Install the Perl module first, then rerun:
  perl planet_elements.pl

If you have Swiss Ephemeris data files, you can also point the script at them:
  perl planet_elements.pl --ephe-path /path/to/ephe
  export SE_EPHE_PATH=/path/to/ephe
MESSAGE
}

sub usage {
    return <<'USAGE';
Usage:
  perl planet_elements.pl [--datetime 2026-08-12T14:30:00] [--ephe-path /path/to/ephe]

Notes:
  --datetime defaults to the current America/Phoenix local time if omitted.
  --datetime without a timezone is interpreted as America/Phoenix.
  --datetime with a trailing Z is interpreted as UTC.
  --ephe-path defaults to $SE_EPHE_PATH when set.
USAGE
}
