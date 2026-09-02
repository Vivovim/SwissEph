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
use Time::Piece;

use lib "$Bin/local/lib/perl5", "$Bin/local/lib/perl5/$Config{archname}";

our $SWISSEPH_LOAD_ERROR;
BEGIN {
    eval {
        require SwissEph;
        1;
    } or do {
        if (!$ENV{SWISSEPH_PERL_REEXEC} && $^X ne '/usr/bin/perl' && -x '/usr/bin/perl') {
            local $ENV{SWISSEPH_PERL_REEXEC} = 1;
            exec '/usr/bin/perl', $0, @ARGV
                or die "Failed to re-exec with /usr/bin/perl: $!\n";
        }

        $SWISSEPH_LOAD_ERROR = $@ || 'Unable to load SwissEph';
    };
}

my $DEFAULT_TZ = 'America/Phoenix';
my $current_year = localtime(time)->year;

my %opt = (
    year      => $current_year,
    timezone  => $DEFAULT_TZ,
    ephe_path => $ENV{SE_EPHE_PATH},
    help      => 0,
);

GetOptions(
    'year=i'      => \$opt{year},
    'timezone=s'  => \$opt{timezone},
    'ephe-path=s' => \$opt{ephe_path},
    'help|h'      => \$opt{help},
) or die usage();

if ($opt{help}) {
    print usage();
    exit 0;
}

die "--year must be a positive integer\n"
    unless defined $opt{year} && $opt{year} =~ /\A\d+\z/ && $opt{year} > 0;

set_timezone($opt{timezone});

die swiss_eph_missing_message()
    if defined $SWISSEPH_LOAD_ERROR;

if (defined $opt{ephe_path} && length $opt{ephe_path}) {
    SwissEph::swe_set_ephe_path($opt{ephe_path});
}

say "Seasonal solar events for $opt{year}";
say "Timezone: $opt{timezone}";
say 'Ephemeris mode: ' . ephemeris_mode_label(\%opt);
say '';

for my $event (seasonal_events()) {
    my $jd = find_event_jd($event, \%opt);
    my $epoch = jd_to_epoch($jd);
    my $utc = gmtime($epoch);
    my $local = localtime($epoch);
    my $longitude = solar_longitude($jd, \%opt);

    say $event->{label};
    say '  UTC:   ' . $utc->strftime('%Y-%m-%d %H:%M:%S UTC');
    say '  Local: ' . $local->strftime('%Y-%m-%d %H:%M:%S %Z');
    say sprintf('  Sun longitude: %.9f deg', normalize_360($longitude));
    say '';
}

SwissEph::swe_close();

sub seasonal_events {
    return (
        {
            label      => 'March Equinox',
            target_deg => 0,
            start_md   => [3, 18],
            end_md     => [3, 22],
        },
        {
            label      => 'June Solstice (Northern Hemisphere Summer)',
            target_deg => 90,
            start_md   => [6, 19],
            end_md     => [6, 23],
        },
        {
            label      => 'September Equinox',
            target_deg => 180,
            start_md   => [9, 20],
            end_md     => [9, 24],
        },
        {
            label      => 'December Solstice (Northern Hemisphere Winter)',
            target_deg => 270,
            start_md   => [12, 20],
            end_md     => [12, 24],
        },
    );
}

sub find_event_jd {
    my ($event, $opt) = @_;

    my $start_jd = utc_components_to_jd($opt->{year}, @{ $event->{start_md} }, 0, 0, 0);
    my $end_jd = utc_components_to_jd($opt->{year}, @{ $event->{end_md} }, 23, 59, 59);
    my $target = $event->{target_deg};
    my $step_days = 0.125;

    my $prev_jd = $start_jd;
    my $prev_error = solar_longitude_error($prev_jd, $target, $opt);

    return $prev_jd if abs($prev_error) < 1e-10;

    for (my $jd = $start_jd + $step_days; $jd <= $end_jd + 1e-12; $jd += $step_days) {
        my $error = solar_longitude_error($jd, $target, $opt);

        return $jd if abs($error) < 1e-10;

        if (($prev_error <= 0 && $error >= 0) || ($prev_error >= 0 && $error <= 0)) {
            return refine_event_time($prev_jd, $jd, $target, $opt);
        }

        $prev_jd = $jd;
        $prev_error = $error;
    }

    die sprintf(
        "Unable to bracket %s in %d between %02d/%02d and %02d/%02d UTC\n",
        $event->{label},
        $opt->{year},
        @{ $event->{start_md} },
        @{ $event->{end_md} },
    );
}

sub refine_event_time {
    my ($lo, $hi, $target, $opt) = @_;

    my $flo = solar_longitude_error($lo, $target, $opt);
    my $fhi = solar_longitude_error($hi, $target, $opt);

    return $lo if abs($flo) < 1e-12;
    return $hi if abs($fhi) < 1e-12;

    my $jd = ($fhi != $flo)
        ? $lo + (($hi - $lo) * (-$flo) / ($fhi - $flo))
        : (($lo + $hi) / 2);

    for (1 .. 12) {
        my ($error, $speed) = solar_error_and_speed($jd, $target, $opt);
        return $jd if abs($error) < 1e-12;

        last if abs($speed) < 1e-12;

        my $next_jd = $jd - ($error / $speed);
        last if $next_jd <= $lo || $next_jd >= $hi;

        $jd = $next_jd;
    }

    for (1 .. 100) {
        my $mid = ($lo + $hi) / 2;
        my $fmid = solar_longitude_error($mid, $target, $opt);

        return $mid if abs($fmid) < 1e-12 || ($hi - $lo) * 86400 < 0.01;

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

sub solar_longitude {
    my ($jd, $opt) = @_;

    my $calc = SwissEph::swe_calc_ut($jd, swe_const('SE_SUN'), base_iflag($opt));
    die "SwissEph sun calc failed: $calc->{serr}\n"
        if defined $calc->{serr} && length $calc->{serr};

    return $calc->{xx}->[0];
}

sub solar_longitude_error {
    my ($jd, $target, $opt) = @_;

    my $longitude = solar_longitude($jd, $opt);
    my $unwrapped = unwrap_angle_near($longitude, $target);
    return $unwrapped - $target;
}

sub solar_error_and_speed {
    my ($jd, $target, $opt) = @_;

    my $iflag = base_iflag($opt) | swe_const('SEFLG_SPEED');
    my $calc = SwissEph::swe_calc_ut($jd, swe_const('SE_SUN'), $iflag);
    die "SwissEph sun calc failed: $calc->{serr}\n"
        if defined $calc->{serr} && length $calc->{serr};

    my $longitude = unwrap_angle_near($calc->{xx}->[0], $target);
    my $error = $longitude - $target;
    my $speed = $calc->{xx}->[3];

    return ($error, $speed);
}

sub utc_components_to_jd {
    my ($year, $month, $day, $hour, $minute, $second) = @_;

    my $jd = SwissEph::swe_utc_to_jd(
        $year,
        $month,
        $day,
        $hour,
        $minute,
        $second + 0,
        swe_const('SE_GREG_CAL'),
    );

    die "SwissEph UTC->JD failed: $jd->{serr}\n"
        if defined $jd->{serr} && length $jd->{serr};

    return $jd->{tjd_ut};
}

sub jd_to_epoch {
    my ($jd) = @_;

    my $unix_seconds = ($jd - 2440587.5) * 86400;
    return int($unix_seconds + ($unix_seconds >= 0 ? 0.5 : -0.5));
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

sub normalize_360 {
    my ($angle) = @_;

    $angle -= 360 * floor($angle / 360);
    $angle += 360 if $angle < 0;

    return $angle;
}

sub unwrap_angle_near {
    my ($angle, $reference) = @_;

    my $unwrapped = normalize_360($angle);
    $unwrapped -= 360 while ($unwrapped - $reference) > 180;
    $unwrapped += 360 while ($unwrapped - $reference) <= -180;

    return $unwrapped;
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

This script calculates the March and September equinoxes plus the June and
December solstices by solving for the Sun's tropical ecliptic longitude.

Install or expose the SwissEph Perl module first, then rerun:
  perl equinox_solstice.pl --year 2026

If you have Swiss Ephemeris data files, you can also point the script at them:
  perl equinox_solstice.pl --year 2026 --ephe-path /path/to/ephe
  export SE_EPHE_PATH=/path/to/ephe
MESSAGE
}

sub usage {
    return <<'USAGE';
Usage:
  perl equinox_solstice.pl [--year YYYY] [--timezone TZ] [--ephe-path PATH]

Examples:
  perl equinox_solstice.pl
  perl equinox_solstice.pl --year 2026
  perl equinox_solstice.pl --year 2026 --timezone UTC
  perl equinox_solstice.pl --year 2026 --ephe-path /path/to/ephe

Calculates:
  - March Equinox
  - June Solstice (Northern Hemisphere Summer)
  - September Equinox
  - December Solstice (Northern Hemisphere Winter)
USAGE
}
