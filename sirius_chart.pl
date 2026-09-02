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
use Time::Local qw(timegm);
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

my %opt = (
    star         => 'Sirius',
    elev         => 0,
    pressure     => 0,
    temperature  => 15,
    start_ts     => time,
    step_unit    => 'days',
    step_size    => 1,
    count        => 12,
    ephe_path    => $ENV{SE_EPHE_PATH},
    house_system => 'P',
);

GetOptions(
    'lat=f'          => \$opt{lat},
    'lon=f'          => \$opt{lon},
    'elev=f'         => \$opt{elev},
    'pressure=f'     => \$opt{pressure},
    'temperature=f'  => \$opt{temperature},
    'start-ts=i'     => \$opt{start_ts},
    'step-unit=s'    => \$opt{step_unit},
    'step-size=i'    => \$opt{step_size},
    'count=i'        => \$opt{count},
    'star=s'         => \$opt{star},
    'ephe-path=s'    => \$opt{ephe_path},
    'house-system=s' => \$opt{house_system},
) or die usage();

for my $required (qw(lat lon)) {
    die usage() unless defined $opt{$required};
}

$opt{step_unit} = normalize_step_unit($opt{step_unit});
die "--step-size must be greater than 0\n" unless $opt{step_size} > 0;
die "--count must be greater than 0\n" unless $opt{count} > 0;
$opt{house_system} = uc substr($opt{house_system}, 0, 1);

die swiss_eph_missing_message()
    if defined $SWISSEPH_LOAD_ERROR;

if (defined $opt{ephe_path} && length $opt{ephe_path}) {
    SwissEph::swe_set_ephe_path($opt{ephe_path});
}

SwissEph::swe_set_topo($opt{lon}, $opt{lat}, $opt{elev});

my $start_epoch = $opt{start_ts};
my $start_jd = epoch_to_jd_utc($start_epoch);
my $iflag = base_iflag(\%opt) | swe_const('SEFLG_TOPOCTR');

my $next_rise_jd = call_rise_trans(
    $start_jd,
    $opt{star},
    $iflag,
    swe_const('SE_CALC_RISE'),
    \%opt,
);

say "Star: $opt{star}";
say "Start timestamp: $start_epoch";
say "Start time (UTC): " . format_epoch_utc($start_epoch);
say sprintf(
    "Location: lat %.6f, lon %.6f, elev %.1f m",
    $opt{lat},
    $opt{lon},
    $opt{elev},
);
say sprintf(
    "Sampling: %d step%s of %d %s",
    $opt{count},
    $opt{count} == 1 ? '' : 's',
    $opt{step_size},
    $opt{step_unit},
);
say "House system: " . SwissEph::swe_house_name($opt{house_system}) . " ($opt{house_system})";
say "Next rise after start (UTC): " . format_jd_utc($next_rise_jd);
say "";
say "Visible events after rise:";

my $visible_count = 0;
my $epoch = $start_epoch;

for my $idx (0 .. $opt{count} - 1) {
    my $jd = epoch_to_jd_utc($epoch);
    my $event = build_star_event($jd, \%opt, $iflag);

    if ($event->{apparent_altitude} > 0) {
        $visible_count++;
        say sprintf("Event %d:", $visible_count);
        say "  Sample timestamp: $epoch";
        say "  Sample time (UTC): " . format_epoch_utc($epoch);
        say "  Rise time (UTC): " . format_jd_utc($event->{rise_jd});
        say "  Zodiac: " . zodiac_sign($event->{longitude});
        say "  Longitude: " . format_longitude($event->{longitude});
        say sprintf(
            "  House: %d (%s, %.4f)",
            $event->{house_num},
            format_house_position($event->{house_pos}),
            $event->{house_pos},
        );
        say sprintf(
            "  Altitude: true %.4f deg, apparent %.4f deg",
            $event->{true_altitude},
            $event->{apparent_altitude},
        );
        say sprintf("  Azimuth: %.4f deg", $event->{azimuth});
        say "";
    }

    $epoch = add_step_epoch($epoch, $opt{step_unit}, $opt{step_size});
}

if (!$visible_count) {
    say "  No sampled events were above the horizon in this window.";
}

SwissEph::swe_close();

sub build_star_event {
    my ($jd, $opt, $iflag) = @_;

    my $star = call_fixstar_ut($opt->{star}, $jd, $iflag);
    my ($longitude, $latitude, $distance) = @{ $star->{xx} }[0, 1, 2];

    my $houses = call_houses_ex(
        $jd,
        base_house_iflag(),
        $opt->{lat},
        $opt->{lon},
        $opt->{house_system},
    );

    my $ecl_nut = call_calc_ut($jd, swe_const('SE_ECL_NUT'), base_iflag($opt));
    my $eps_true = $ecl_nut->{xx}->[0];

    my $house_pos = call_house_pos(
        $houses->{armc},
        $opt->{lat},
        $eps_true,
        $opt->{house_system},
        $longitude,
        $latitude,
    );

    my $azalt = call_azalt(
        $jd,
        swe_const('SE_ECL2HOR'),
        $opt->{lon},
        $opt->{lat},
        $opt->{elev},
        $opt->{pressure},
        $opt->{temperature},
        $longitude,
        $latitude,
        $distance,
    );

    my $rise_jd = find_previous_rise_jd($jd, $opt, $iflag);

    return {
        longitude         => $longitude,
        latitude          => $latitude,
        distance          => $distance,
        house_pos         => $house_pos->{dhpos},
        house_num         => $house_pos->{ihno},
        azimuth           => $azalt->[0],
        true_altitude     => $azalt->[1],
        apparent_altitude => $azalt->[2],
        rise_jd           => $rise_jd,
    };
}

sub call_fixstar_ut {
    my ($star_name, $jd, $iflag) = @_;

    my $raw = SwissEph::swe_fixstar_ut($star_name, $jd, $iflag);

    if (ref($raw) eq 'HASH') {
        my $xx = $raw->{xx} || $raw->{xreturn} || [];
        die "SwissEph fixed star result missing coordinates\n" unless ref($xx) eq 'ARRAY' && @$xx >= 3;

        if (defined $raw->{serr} && length $raw->{serr}) {
            die "SwissEph fixed star calc failed for $star_name: $raw->{serr}\n";
        }

        return {
            xx    => $xx,
            stnam => $raw->{star} // $raw->{stnam} // $raw->{starname} // $star_name,
        };
    }

    if (ref($raw) eq 'ARRAY' && @$raw >= 6) {
        my @xx = @$raw[0 .. 5];
        return {
            xx    => \@xx,
            stnam => $raw->[6] // $star_name,
        };
    }

    die "Unexpected SwissEph fixed star result for $star_name\n";
}

sub call_calc_ut {
    my ($jd, $body, $iflag) = @_;

    my $raw = SwissEph::swe_calc_ut($jd, $body, $iflag);

    if (ref($raw) eq 'HASH') {
        die "SwissEph calc failed: $raw->{serr}\n"
            if defined $raw->{serr} && length $raw->{serr};
        return $raw;
    }

    if (ref($raw) eq 'ARRAY' && @$raw >= 6) {
        return { xx => $raw };
    }

    die "Unexpected SwissEph calc result\n";
}

sub call_houses_ex {
    my ($jd, $iflag, $lat, $lon, $house_system) = @_;

    my $raw = SwissEph::swe_houses_ex($jd, $iflag, $lat, $lon, $house_system);

    if (ref($raw) eq 'HASH') {
        die "SwissEph houses failed: $raw->{serr}\n"
            if defined $raw->{serr} && length $raw->{serr};
        return $raw;
    }

    if (ref($raw) eq 'ARRAY' && @$raw >= 2) {
        my ($cusps, $ascmc) = @$raw;
        return {
            cusps => $cusps,
            ascmc => $ascmc,
            armc  => $ascmc->[2],
            asc   => $ascmc->[0],
            mc    => $ascmc->[1],
        };
    }

    die "Unexpected SwissEph houses result\n";
}

sub call_house_pos {
    my ($armc, $lat, $eps, $house_system, $ecl_lon, $ecl_lat) = @_;

    my $raw = SwissEph::swe_house_pos($armc, $lat, $eps, $house_system, $ecl_lon, $ecl_lat);

    if (ref($raw) eq 'HASH') {
        die "SwissEph house position failed: $raw->{serr}\n"
            if defined $raw->{serr} && length $raw->{serr};
        return $raw;
    }

    if (!ref($raw)) {
        my $dhpos = $raw + 0;
        return {
            dhpos => $dhpos,
            ihno  => house_number_from_pos($dhpos),
        };
    }

    die "Unexpected SwissEph house position result\n";
}

sub call_azalt {
    my ($jd, $flag, $lon, $lat, $elev, $pressure, $temperature, @coords) = @_;

    my @raw = SwissEph::swe_azalt(
        $jd,
        $flag,
        [ $lon, $lat, $elev ],
        $pressure,
        $temperature,
        [ @coords ],
    );

    if (@raw >= 3 && !grep { ref($_) } @raw[0 .. 2]) {
        return [ @raw[0 .. 2] ];
    }

    my $raw = @raw == 1 ? $raw[0] : \@raw;

    if (ref($raw) eq 'ARRAY' && @$raw >= 3) {
        return $raw;
    }

    if (ref($raw) eq 'HASH' && ref($raw->{xaz}) eq 'ARRAY' && @{ $raw->{xaz} } >= 3) {
        return $raw->{xaz};
    }

    die "Unexpected SwissEph azimuth/altitude result\n";
}

sub call_rise_trans {
    my ($jd, $body_or_star, $epheflag, $rsmi, $opt) = @_;

    my $ipl = 0;
    my $star = undef;

    if (defined $body_or_star && !ref($body_or_star) && $body_or_star =~ /\A-?\d+\z/) {
        $ipl = $body_or_star;
    }
    else {
        $star = $body_or_star;
    }

    my $raw = SwissEph::swe_rise_trans(
        $jd,
        $ipl,
        $star,
        $epheflag,
        $rsmi,
        [ $opt->{lon}, $opt->{lat}, $opt->{elev} ],
        $opt->{pressure},
        $opt->{temperature},
    );

    if (ref($raw) eq 'HASH') {
        die "SwissEph rise/set failed: $raw->{serr}\n"
            if defined $raw->{serr} && length $raw->{serr};

        return $raw->{tret}
            if exists $raw->{tret} && !ref($raw->{tret});

        return $raw->{tret}->[0]
            if ref($raw->{tret}) eq 'ARRAY' && @{ $raw->{tret} };

        return $raw->{dret}
            if exists $raw->{dret} && !ref($raw->{dret});

        return $raw->{dret}->[0]
            if ref($raw->{dret}) eq 'ARRAY' && @{ $raw->{dret} };
    }

    return $raw + 0 if !ref($raw);

    if (ref($raw) eq 'ARRAY' && @$raw) {
        return $raw->[0] + 0;
    }

    die "Unexpected SwissEph rise/set result\n";
}

sub find_previous_rise_jd {
    my ($sample_jd, $opt, $iflag) = @_;

    for my $lookback_days (1.5, 2.5, 3.5) {
        my $rise_jd = call_rise_trans(
            $sample_jd - $lookback_days,
            $opt->{star},
            $iflag,
            swe_const('SE_CALC_RISE'),
            $opt,
        );

        return $rise_jd if $rise_jd <= $sample_jd + 1e-8;
    }

    die sprintf("Unable to find a rise time for %s before JD %.8f\n", $opt->{star}, $sample_jd);
}

sub base_iflag {
    my ($opt) = @_;
    return swe_const('SEFLG_SWIEPH') if defined $opt->{ephe_path} && length $opt->{ephe_path};
    return swe_const('SEFLG_MOSEPH');
}

sub base_house_iflag {
    return 0;
}

sub swe_const {
    my ($name) = @_;

    die swiss_eph_missing_message()
        if defined $SWISSEPH_LOAD_ERROR;

    no strict 'refs';
    my $full_name = "SwissEph::$name";
    die "SwissEph constant $name is not available\n" unless defined &{$full_name};
    return &{$full_name}();
}

sub epoch_to_jd_utc {
    my ($epoch) = @_;

    my $utc = gmtime($epoch);
    my $hour = $utc->hour + ($utc->min / 60) + (($utc->sec + 0) / 3600);
    return SwissEph::swe_julday(
        $utc->year,
        $utc->mon,
        $utc->mday,
        $hour,
        swe_const('SE_GREG_CAL'),
    );
}

sub jd_to_epoch {
    my ($jd) = @_;
    return int((($jd - 2440587.5) * 86400) + 0.5);
}

sub add_step_epoch {
    my ($epoch, $unit, $step_size) = @_;

    return $epoch + ($step_size * 86_400) if $unit eq 'days';

    my $utc = gmtime($epoch);
    my $year = $utc->year;
    my $month = $utc->mon;
    my $day = $utc->mday;

    my $target_month_index = ($month - 1) + $step_size;
    $year += int($target_month_index / 12);
    $target_month_index %= 12;

    if ($target_month_index < 0) {
        $target_month_index += 12;
        $year -= 1;
    }

    my $target_month = $target_month_index + 1;
    my $clamped_day = $day;
    my $last_day = days_in_month($year, $target_month);
    $clamped_day = $last_day if $clamped_day > $last_day;

    return timegm(
        $utc->sec,
        $utc->min,
        $utc->hour,
        $clamped_day,
        $target_month - 1,
        $year,
    );
}

sub days_in_month {
    my ($year, $month) = @_;

    return 31 if $month == 1 || $month == 3 || $month == 5 || $month == 7 || $month == 8 || $month == 10 || $month == 12;
    return 30 if $month == 4 || $month == 6 || $month == 9 || $month == 11;

    return is_leap_year($year) ? 29 : 28;
}

sub is_leap_year {
    my ($year) = @_;
    return 1 if $year % 400 == 0;
    return 0 if $year % 100 == 0;
    return $year % 4 == 0 ? 1 : 0;
}

sub house_number_from_pos {
    my ($dhpos) = @_;

    my $house = int($dhpos);
    $house = 1 if $house < 1;
    $house = 12 if $house > 12;
    return $house;
}

sub normalize_step_unit {
    my ($input) = @_;

    my $unit = lc($input // '');
    return 'days'   if $unit eq 'day'   || $unit eq 'days';
    return 'months' if $unit eq 'month' || $unit eq 'months';
    die "--step-unit must be one of: day, days, month, months\n";
}

sub zodiac_sign {
    my ($longitude) = @_;

    my @signs = qw(Aries Taurus Gemini Cancer Leo Virgo Libra Scorpio Sagittarius Capricorn Aquarius Pisces);
    my $normalized = normalize_360($longitude);
    return $signs[int($normalized / 30)];
}

sub normalize_360 {
    my ($angle) = @_;
    $angle %= 360;
    $angle += 360 if $angle < 0;
    return $angle;
}

sub format_longitude {
    my ($longitude) = @_;

    my @signs = qw(Aries Taurus Gemini Cancer Leo Virgo Libra Scorpio Sagittarius Capricorn Aquarius Pisces);
    my $normalized = normalize_360($longitude);
    my $sign_index = int($normalized / 30);
    my $sign_degrees = $normalized - ($sign_index * 30);
    my $degrees = int($sign_degrees);
    my $minutes_full = ($sign_degrees - $degrees) * 60;
    my $minutes = int($minutes_full);
    my $seconds = int((($minutes_full - $minutes) * 60) + 0.5);

    if ($seconds == 60) {
        $seconds = 0;
        $minutes += 1;
    }

    if ($minutes == 60) {
        $minutes = 0;
        $degrees += 1;
    }

    if ($degrees == 30) {
        $degrees = 0;
        $sign_index = ($sign_index + 1) % 12;
    }

    return sprintf('%02dd %02dm %02ds %s', $degrees, $minutes, $seconds, $signs[$sign_index]);
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

sub format_jd_utc {
    my ($jd) = @_;
    return format_epoch_utc(jd_to_epoch($jd));
}

sub format_epoch_utc {
    my ($epoch) = @_;
    return gmtime($epoch)->strftime('%Y-%m-%d %H:%M:%S');
}

sub swiss_eph_missing_message {
    my $detail = defined $SWISSEPH_LOAD_ERROR ? $SWISSEPH_LOAD_ERROR : 'Unknown error';

    return <<"MSG";
SwissEph could not be loaded in this workspace.

This script expects the Perl Swiss Ephemeris module plus the underlying Swiss
Ephemeris shared library to be installed. The current load error was:
$detail

If you already have Swiss Ephemeris data files, you can also point the script
at them with --ephe-path PATH. Fixed-star calculations for Sirius usually need
the Swiss Ephemeris star catalog file `sefstars.txt` available in that path.
MSG
}

sub usage {
    return <<'USAGE';
Usage:
  perl sirius_chart.pl --lat LAT --lon LON [options]

Required:
  --lat LAT              Geographic latitude in degrees
  --lon LON              Geographic longitude in degrees

Options:
  --start-ts TS          Unix timestamp to start from (default: current time)
  --step-unit UNIT       day|days|month|months (default: days)
  --step-size N          Step size for each sample (default: 1)
  --count N              Number of sampled events to inspect (default: 12)
  --elev METERS          Elevation above sea level (default: 0)
  --pressure MBAR        Atmospheric pressure for altitude calc (default: 0)
  --temperature C        Temperature for altitude calc (default: 15)
  --house-system CHAR    House system, e.g. P for Placidus (default: P)
  --star NAME            Fixed star name (default: Sirius)
  --ephe-path PATH       Swiss Ephemeris data directory

What it prints:
  - the zodiac sign Sirius is in
  - the house Sirius is in
  - the rise time for each visible sampled event
  - only sampled events where Sirius is above the horizon
USAGE
}
