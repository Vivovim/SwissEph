package MoonAge;

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

use Config ();
use Carp qw(croak);
use Exporter qw(import);
use File::Basename qw(dirname);
use POSIX qw(floor);

our @EXPORT_OK = qw(moon_age_days);
our $VERSION   = '0.01';

BEGIN {
    my $root_dir  = dirname(__FILE__);
    my $local_lib = "$root_dir/local/lib/perl5";
    my $arch_lib  = "$local_lib/$Config::Config{archname}";

    require lib;

    my @paths;
    push @paths, $local_lib if -d $local_lib;
    push @paths, $arch_lib  if -d $arch_lib;

    lib->import(@paths) if @paths;
}

use SwissEph qw(:all);

my $HAS_SWIEPH = eval { my $flag = SEFLG_SWIEPH; defined $flag } ? 1 : 0;

sub moon_age_days {
    my (%args) = @_ == 1 && !ref $_[0]
        ? (timestamp => $_[0])
        : @_;

    my $current_phase_timestamp = exists $args{timestamp} ? $args{timestamp} : time;
    croak 'timestamp must be a Unix epoch number'
        if !defined $current_phase_timestamp
        || $current_phase_timestamp !~ /\A-?(?:\d+(?:\.\d*)?|\.\d+)\z/;

    my $ephe_path = $args{ephe_path};

    my $age_days = eval {
        swe_set_ephe_path($ephe_path)
            if defined $ephe_path && length $ephe_path;

        my $current_phase_jd      = epoch_to_jd($current_phase_timestamp);
        my $last_new_moon_jd      = find_previous_phase($current_phase_jd, 0, $ephe_path);
        my $last_new_moon_time    = jd_to_epoch_seconds($last_new_moon_jd);
        my $moon_age_in_days      = ($current_phase_timestamp - $last_new_moon_time) / 86400;

        return $moon_age_in_days;
    };

    my $error = $@;
    eval { swe_close() };
    die $error if $error;

    return $age_days;
}

sub find_previous_phase {
    my ($start_jd, $target_deg, $ephe_path) = @_;

    my $step_days  = 0.125;
    my $max_days   = 40;
    my $tol_angle  = 1e-7;
    my $target     = $target_deg;
    my $previous_jd    = $start_jd;
    my $previous_phase = phase_angle($previous_jd, $ephe_path);

    $target -= 360 while $target > ($previous_phase + $tol_angle);

    my $max_steps = int($max_days / $step_days) + 2;

    for my $step (1 .. $max_steps) {
        my $jd    = $start_jd - ($step * $step_days);
        my $phase = unwrap_phase_near(phase_angle($jd, $ephe_path), $previous_phase);
        $phase -= 360 while $phase > $previous_phase;

        if ($phase <= $target) {
            return refine_phase_time($jd, $previous_jd, $target, $ephe_path);
        }

        $previous_jd    = $jd;
        $previous_phase = $phase;
    }

    die sprintf('Unable to find previous %.0f-degree phase before JD %.8f', $target_deg, $start_jd);
}

sub refine_phase_time {
    my ($lo, $hi, $target_phase, $ephe_path) = @_;

    my $flo = phase_error($lo, $target_phase, $ephe_path);
    my $fhi = phase_error($hi, $target_phase, $ephe_path);

    return $lo if abs($flo) < 1e-10;
    return $hi if abs($fhi) < 1e-10;

    my $jd = ($lo + $hi) / 2;

    for (1 .. 20) {
        my ($error, $speed) = phase_error_and_speed($jd, $target_phase, $ephe_path);
        return $jd if abs($error) < 1e-9;
        last if abs($speed) < 1e-9;

        my $next_jd = $jd - ($error / $speed);
        last if $next_jd <= $lo || $next_jd >= $hi;

        $jd = $next_jd;
    }

    for (1 .. 100) {
        my $mid  = ($lo + $hi) / 2;
        my $fmid = phase_error($mid, $target_phase, $ephe_path);

        return $mid if abs($fmid) < 1e-10 || ($hi - $lo) * 86400 < 0.25;

        if (($flo < 0 && $fmid < 0) || ($flo > 0 && $fmid > 0)) {
            $lo  = $mid;
            $flo = $fmid;
        }
        else {
            $hi  = $mid;
            $fhi = $fmid;
        }
    }

    return ($lo + $hi) / 2;
}

sub phase_angle {
    my ($jd, $ephe_path) = @_;

    my $iflag = base_iflag($ephe_path);
    my $sun   = calc_body($jd, SE_SUN,  $iflag);
    my $moon  = calc_body($jd, SE_MOON, $iflag);

    return normalize_360($moon->{xx}[0] - $sun->{xx}[0]);
}

sub phase_error {
    my ($jd, $target_phase, $ephe_path) = @_;

    my $phase = unwrap_phase_near(phase_angle($jd, $ephe_path), $target_phase);
    return $phase - $target_phase;
}

sub phase_error_and_speed {
    my ($jd, $target_phase, $ephe_path) = @_;

    my $iflag = base_iflag($ephe_path) | SEFLG_SPEED;
    my $sun   = calc_body($jd, SE_SUN,  $iflag);
    my $moon  = calc_body($jd, SE_MOON, $iflag);

    my $phase = unwrap_phase_near(
        normalize_360($moon->{xx}[0] - $sun->{xx}[0]),
        $target_phase,
    );

    my $error = $phase - $target_phase;
    my $speed = $moon->{xx}[3] - $sun->{xx}[3];

    return ($error, $speed);
}

sub calc_body {
    my ($jd, $body, $iflag) = @_;

    my $calc = swe_calc_ut($jd, $body, $iflag);
    die "SwissEph calc failed: $calc->{serr}\n"
        if defined $calc->{serr} && length $calc->{serr};

    return $calc;
}

sub epoch_to_jd {
    my ($timestamp) = @_;

    my $whole_seconds = int($timestamp);
    my $fractional    = $timestamp - $whole_seconds;
    my @utc           = gmtime($whole_seconds);

    my $jd = swe_utc_to_jd(
        $utc[5] + 1900,
        $utc[4] + 1,
        $utc[3],
        $utc[2],
        $utc[1],
        $utc[0] + $fractional,
        SE_GREG_CAL,
    );

    die "SwissEph UTC->JD failed: $jd->{serr}\n"
        if defined $jd->{serr} && length $jd->{serr};

    return $jd->{tjd_ut};
}

sub jd_to_epoch_seconds {
    my ($jd) = @_;
    return ($jd - 2440587.5) * 86400;
}

sub base_iflag {
    my ($ephe_path) = @_;
    return SEFLG_SWIEPH if $HAS_SWIEPH && defined $ephe_path && length $ephe_path;
    return SEFLG_MOSEPH;
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

1;
