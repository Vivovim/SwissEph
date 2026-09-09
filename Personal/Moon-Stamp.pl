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
use Time::Local qw(timegm);
use Time::Piece;
use lib "$Bin/local/lib/perl5", "$Bin/local/lib/perl5/$Config{archname}";

use SwissEph qw(:all);

my $LOCAL_TZ = 'America/Phoenix';
set_timezone($LOCAL_TZ);
my $HAS_SWIEPH = eval { my $flag = SEFLG_SWIEPH; defined $flag } ? 1 : 0;

my %opt = (
    debug     => 0,
    ephe_path => $ENV{SE_EPHE_PATH},
    timestamp => undef,
);

GetOptions(
    'debug!'      => \$opt{debug},
    'ephe-path=s' => \$opt{ephe_path},
    'timestamp=s' => \$opt{timestamp},
) or die usage();

if (defined $opt{ephe_path} && length $opt{ephe_path}) {
    swe_set_ephe_path($opt{ephe_path});
}

my $unix_timestamp = defined $opt{timestamp}
    ? parse_timestamp_utc($opt{timestamp})
    : time;

my $local_time = localtime($unix_timestamp);
my $utc_time = gmtime($unix_timestamp);
my $jd = utc_to_jd($utc_time);
my $iflag = base_iflag(\%opt);

my $moon = swe_calc_ut($jd, SE_MOON, $iflag);
die "SwissEph moon calc failed: $moon->{serr}\n"
    if defined $moon->{serr} && length $moon->{serr};

my $sun = swe_calc_ut($jd, SE_SUN, $iflag);
die "SwissEph sun calc failed: $sun->{serr}\n"
    if defined $sun->{serr} && length $sun->{serr};

my $moon_longitude = $moon->{xx}->[0];
my $phase_angle = normalize_360($moon_longitude - $sun->{xx}->[0]);
my $phase_name = current_phase_name($phase_angle);
my $moon_sign = zodiac_sign($moon_longitude);
my $previous_new_moon_jd = find_previous_phase($jd, 0, \%opt);
my $moon_age_days = $jd - $previous_new_moon_jd;
my $previous_new_moon_epoch = jd_to_epoch($previous_new_moon_jd);

say "Unix timestamp: $unix_timestamp";
say "Timestamp source: " . (defined $opt{timestamp} ? '--timestamp (UTC)' : 'system clock');
say "Timestamp ($LOCAL_TZ): " . $local_time->strftime('%Y-%m-%d %H:%M:%S');
say "Timestamp (UTC): " . $utc_time->strftime('%Y-%m-%d %H:%M:%S');
say "Ephemeris mode: " . ephemeris_mode_label(\%opt);
say sprintf("Moon phase: %s (phase angle %.6f deg)", $phase_name, $phase_angle);
say "Moon zodiac: $moon_sign";
say "Moon longitude: " . format_longitude($moon_longitude);
say sprintf("Moon age: %.6f days since New Moon", $moon_age_days);

if ($opt{debug}) {
    say "Previous New Moon ($LOCAL_TZ): "
        . localtime($previous_new_moon_epoch)->strftime('%Y-%m-%d %H:%M:%S');
    say "Previous New Moon (UTC): "
        . gmtime($previous_new_moon_epoch)->strftime('%Y-%m-%d %H:%M:%S');
}

swe_close();

sub find_previous_phase {
    my ($start_jd, $target_deg, $opt) = @_;

    my $step_days = 0.125;
    my $max_days = 40;
    my $tol_angle = 1e-7;

    my $prev_jd = $start_jd;
    my $prev_phase = phase_angle($prev_jd, $opt);
    my $target_phase = $target_deg;

    $target_phase -= 360 while $target_phase > ($prev_phase + $tol_angle);
    my $max_steps = int($max_days / $step_days) + 2;

    for my $step (1 .. $max_steps) {
        my $jd = $start_jd - ($step * $step_days);
        my $phase = unwrap_phase_near(phase_angle($jd, $opt), $prev_phase);
        $phase -= 360 while $phase > $prev_phase;

        if ($phase <= $target_phase) {
            return refine_phase_time($jd, $prev_jd, $target_phase, $opt);
        }

        $prev_jd = $jd;
        $prev_phase = $phase;
    }

    die sprintf("Unable to find previous %.0f-degree phase before JD %.8f\n", $target_deg, $start_jd);
}

sub refine_phase_time {
    my ($lo, $hi, $target_phase, $opt) = @_;

    my $flo = phase_error($lo, $target_phase, $opt);
    my $fhi = phase_error($hi, $target_phase, $opt);

    return $lo if abs($flo) < 1e-10;
    return $hi if abs($fhi) < 1e-10;

    my $jd = ($lo + $hi) / 2;

    for (1 .. 20) {
        my ($error, $speed) = phase_error_and_speed($jd, $target_phase, $opt);
        return $jd if abs($error) < 1e-9;

        last if abs($speed) < 1e-9;

        my $next_jd = $jd - ($error / $speed);
        last if $next_jd <= $lo || $next_jd >= $hi;

        $jd = $next_jd;
    }

    for (1 .. 100) {
        my $mid = ($lo + $hi) / 2;
        my $fmid = phase_error($mid, $target_phase, $opt);

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

sub phase_angle {
    my ($jd, $opt) = @_;

    my $iflag = base_iflag($opt);
    my $sun = swe_calc_ut($jd, SE_SUN, $iflag);
    die "SwissEph sun calc failed: $sun->{serr}\n"
        if defined $sun->{serr} && length $sun->{serr};

    my $moon = swe_calc_ut($jd, SE_MOON, $iflag);
    die "SwissEph moon calc failed: $moon->{serr}\n"
        if defined $moon->{serr} && length $moon->{serr};

    return normalize_360($moon->{xx}->[0] - $sun->{xx}->[0]);
}

sub phase_error {
    my ($jd, $target_phase, $opt) = @_;

    my $phase = unwrap_phase_near(phase_angle($jd, $opt), $target_phase);
    return $phase - $target_phase;
}

sub phase_error_and_speed {
    my ($jd, $target_phase, $opt) = @_;

    my $iflag = base_iflag($opt) | SEFLG_SPEED;
    my $sun = swe_calc_ut($jd, SE_SUN, $iflag);
    die "SwissEph sun calc failed: $sun->{serr}\n"
        if defined $sun->{serr} && length $sun->{serr};

    my $moon = swe_calc_ut($jd, SE_MOON, $iflag);
    die "SwissEph moon calc failed: $moon->{serr}\n"
        if defined $moon->{serr} && length $moon->{serr};

    my $phase = unwrap_phase_near(
        normalize_360($moon->{xx}->[0] - $sun->{xx}->[0]),
        $target_phase,
    );
    my $error = $phase - $target_phase;

    my $speed = $moon->{xx}->[3] - $sun->{xx}->[3];
    return ($error, $speed);
}

sub current_phase_name {
    my ($phase_angle) = @_;

    return 'New Moon'        if $phase_angle < 22.5 || $phase_angle >= 337.5;
    return 'Waxing Crescent' if $phase_angle < 67.5;
    return 'First Quarter'   if $phase_angle < 112.5;
    return 'Waxing Gibbous'  if $phase_angle < 157.5;
    return 'Full Moon'       if $phase_angle < 202.5;
    return 'Waning Gibbous'  if $phase_angle < 247.5;
    return 'Last Quarter'    if $phase_angle < 292.5;
    return 'Waning Crescent';
}

sub zodiac_sign {
    my ($longitude) = @_;

    my @signs = qw(Aries Taurus Gemini Cancer Leo Virgo Libra Scorpio Sagittarius Capricorn Aquarius Pisces);
    my $normalized = normalize_360($longitude);
    return $signs[int($normalized / 30)];
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

sub jd_to_epoch {
    my ($jd) = @_;

    my $unix_seconds = ($jd - 2440587.5) * 86400;
    return int($unix_seconds + ($unix_seconds >= 0 ? 0.5 : -0.5));
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

sub normalize_360 {
    my ($angle) = @_;
    $angle -= 360 * floor($angle / 360);
    $angle += 360 if $angle < 0;
    return $angle;
}

sub unwrap_phase_near {
    my ($phase, $reference) = @_;

    $phase -= 360 while ($phase - $reference) > 180;
    $phase += 360 while ($phase - $reference) <= -180;
    return $phase;
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

sub parse_timestamp_utc {
    my ($value) = @_;

    $value =~ s/^\s+//;
    $value =~ s/\s+$//;

    return 0 + $value if $value =~ /\A-?\d+\z/;

    if ($value =~ /\A(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})(?::(\d{2}))?(?:Z)?\z/) {
        my ($year, $mon, $mday, $hour, $min, $sec) = ($1, $2, $3, $4, $5, $6 // 0);
        my $epoch = eval { timegm($sec, $min, $hour, $mday, $mon - 1, $year) };

        die "Invalid --timestamp value: $value\n" if $@;

        my $check = gmtime($epoch);
        if (
            $check->year != $year
            || $check->mon != $mon
            || $check->mday != $mday
            || $check->hour != $hour
            || $check->min != $min
            || $check->sec != $sec
        ) {
            die "Invalid --timestamp value: $value\n";
        }

        return $epoch;
    }

    die <<"ERROR";
Invalid --timestamp value: $value
Expected a Unix timestamp or a UTC datetime like 2026-08-26T12:34:56Z
ERROR
}

sub set_timezone {
    my ($tz) = @_;
    $ENV{TZ} = $tz;
    tzset();
}

sub usage {
    return <<'USAGE';
Usage:
  perl Moon-Stamp.pl [--timestamp VALUE] [--ephe-path PATH] [--debug]

Calculate the Moon's phase for a specific UTC moment.

--timestamp accepts either:
  - a Unix timestamp
  - a UTC datetime like 2026-08-26T12:34:56Z
  - a UTC datetime like 2026-08-26 12:34:56

If --timestamp is omitted, the current system time is used.
USAGE
}
