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

my %opt = (
    elev        => 0,
    pressure    => 0,
    temperature => 15,
    start_date  => undef,
    days        => 1,
    step_days   => 1,
    ephe_path   => $ENV{SE_EPHE_PATH},
    tz          => ((defined $ENV{TZ} && length $ENV{TZ}) ? $ENV{TZ} : 'America/Phoenix'),
    header      => 1,
    help        => 0,
);

GetOptions(
    'lat=f'         => \$opt{lat},
    'lon=f'         => \$opt{lon},
    'elev=f'        => \$opt{elev},
    'pressure=f'    => \$opt{pressure},
    'temperature=f' => \$opt{temperature},
    'start-date=s'  => \$opt{start_date},
    'days=i'        => \$opt{days},
    'step-days=i'   => \$opt{step_days},
    'ephe-path=s'   => \$opt{ephe_path},
    'tz=s'          => \$opt{tz},
    'header!'       => \$opt{header},
    'help'          => \$opt{help},
) or die usage();

if ($opt{help}) {
    print usage();
    exit 0;
}

for my $required (qw(lat lon)) {
    die usage() unless defined $opt{$required};
}

die "--days must be greater than 0\n" unless $opt{days} > 0;
die "--step-days must be greater than 0\n" unless $opt{step_days} > 0;
validate_coordinates(\%opt);

set_timezone($opt{tz});
$opt{start_date} = localtime(time)->strftime('%Y-%m-%d')
    unless defined $opt{start_date} && length $opt{start_date};

my ($start_year, $start_month, $start_day) = parse_date($opt{start_date});

die swiss_eph_missing_message()
    if defined $SWISSEPH_LOAD_ERROR;

if (defined $opt{ephe_path} && length $opt{ephe_path}) {
    SwissEph::swe_set_ephe_path($opt{ephe_path});
}

SwissEph::swe_set_topo($opt{lon}, $opt{lat}, $opt{elev});

my $rise_set_iflag = base_iflag(\%opt) | swe_const('SEFLG_TOPOCTR');

if ($opt{header}) {
    say join("\t", 'date', 'moonrise', 'moonset');
}

for my $row_index (0 .. $opt{days} - 1) {
    my ($year, $month, $day) = add_days_to_date(
        $start_year,
        $start_month,
        $start_day,
        $row_index * $opt{step_days},
    );

    my $date_label = sprintf('%04d-%02d-%02d', $year, $month, $day);
    my $start_epoch_local = timelocal(0, 0, 0, $day, $month - 1, $year);
    my $end_epoch_local = $start_epoch_local + 24 * 3600;

    my $moonrise_jd = event_for_local_window(
        $start_epoch_local,
        $end_epoch_local,
        $date_label,
        swe_const('SE_CALC_RISE'),
        \%opt,
        $rise_set_iflag,
    );
    my $moonset_jd = event_for_local_window(
        $start_epoch_local,
        $end_epoch_local,
        $date_label,
        swe_const('SE_CALC_SET'),
        \%opt,
        $rise_set_iflag,
    );

    say join(
        "\t",
        $date_label,
        format_event_local_time($moonrise_jd),
        format_event_local_time($moonset_jd),
    );
}

SwissEph::swe_close();

sub event_for_local_window {
    my ($start_epoch_local, $end_epoch_local, $wanted_date, $rsmi, $opt, $iflag) = @_;

    my @seed_jds = utc_midnight_seed_jds($start_epoch_local, $end_epoch_local);
    my @matching_events;

    for my $seed_jd (@seed_jds) {
        my $event_jd = call_rise_trans(
            $seed_jd,
            swe_const('SE_MOON'),
            $iflag,
            $rsmi,
            $opt,
        );

        next unless defined $event_jd;

        my $event_epoch = jd_to_epoch($event_jd);
        next if $event_epoch < $start_epoch_local || $event_epoch >= $end_epoch_local;

        my $event_date = localtime($event_epoch)->strftime('%Y-%m-%d');
        next unless $event_date eq $wanted_date;

        push @matching_events, $event_jd;
    }

    return undef unless @matching_events;

    @matching_events = sort { $a <=> $b } @matching_events;
    return $matching_events[0];
}

sub utc_midnight_seed_jds {
    my ($start_epoch_local, $end_epoch_local) = @_;

    my %seen;
    my @seed_jds;

    for my $epoch ($start_epoch_local, $end_epoch_local - 1) {
        my $utc = gmtime($epoch);
        my $label = sprintf('%04d-%02d-%02d', $utc->year, $utc->mon, $utc->mday);
        next if $seen{$label}++;

        push @seed_jds, SwissEph::swe_julday(
            $utc->year,
            $utc->mon,
            $utc->mday,
            0,
            swe_const('SE_GREG_CAL'),
        );
    }

    return @seed_jds;
}

sub call_rise_trans {
    my ($jd, $body, $epheflag, $rsmi, $opt) = @_;

    my $raw = SwissEph::swe_rise_trans(
        $jd,
        $body,
        '',
        $epheflag,
        $rsmi,
        [ $opt->{lon}, $opt->{lat}, $opt->{elev} ],
        $opt->{pressure},
        $opt->{temperature},
    );

    if (ref($raw) eq 'HASH') {
        if (defined $raw->{serr} && length $raw->{serr}) {
            return undef if $raw->{serr} =~ /never rises|never sets|circumpolar|no rise\/set|rise or set not found/i;
            die "SwissEph rise/set failed: $raw->{serr}\n";
        }

        return $raw->{tret}
            if exists $raw->{tret} && defined $raw->{tret} && !ref($raw->{tret});

        return $raw->{tret}->[0]
            if ref($raw->{tret}) eq 'ARRAY' && @{ $raw->{tret} };

        return $raw->{dret}
            if exists $raw->{dret} && defined $raw->{dret} && !ref($raw->{dret});

        return $raw->{dret}->[0]
            if ref($raw->{dret}) eq 'ARRAY' && @{ $raw->{dret} };

        return undef;
    }

    return $raw + 0 if defined $raw && !ref($raw);

    if (ref($raw) eq 'ARRAY' && @$raw) {
        return $raw->[0] + 0;
    }

    return undef;
}

sub base_iflag {
    my ($opt) = @_;
    return swe_const('SEFLG_SWIEPH') if defined $opt->{ephe_path} && length $opt->{ephe_path};
    return swe_const('SEFLG_MOSEPH');
}

sub swe_const {
    my ($name) = @_;

    no strict 'refs';
    my $full_name = "SwissEph::$name";
    die "SwissEph constant $name is not available\n" unless defined &{$full_name};
    return &{$full_name}();
}

sub epoch_to_jd_utc {
    my ($epoch) = @_;

    my $utc = gmtime($epoch);
    my $hour = $utc->hour + ($utc->min / 60) + ($utc->sec / 3600);

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

sub format_event_local_time {
    my ($jd) = @_;
    return 'None in window' unless defined $jd;
    return localtime(jd_to_epoch($jd))->strftime('%H:%M:%S');
}

sub set_timezone {
    my ($tz) = @_;
    $ENV{TZ} = $tz;
    tzset();
}

sub validate_coordinates {
    my ($opt) = @_;

    if (abs($opt->{lat}) > 90 && abs($opt->{lon}) <= 90) {
        die <<"MSG";
The coordinates look reversed.

You passed:
  --lat $opt->{lat}
  --lon $opt->{lon}

Latitude must be between -90 and 90. For a location near Prescott, Arizona,
you probably want:
  --lat 34.5842 --lon -112.4852
MSG
    }

    die "--lat must be between -90 and 90 degrees\n"
        if $opt->{lat} < -90 || $opt->{lat} > 90;

    die "--lon must be between -180 and 180 degrees\n"
        if $opt->{lon} < -180 || $opt->{lon} > 180;
}

sub parse_date {
    my ($date_text) = @_;

    my ($year, $month, $day) = $date_text =~ /\A(\d{4})-(\d{2})-(\d{2})\z/
        or die "--start-date must be in YYYY-MM-DD format\n";

    die "--start-date month must be between 01 and 12\n"
        if $month < 1 || $month > 12;

    my $last_day = days_in_month($year, $month);
    die "--start-date day is out of range for the month\n"
        if $day < 1 || $day > $last_day;

    return ($year + 0, $month + 0, $day + 0);
}

sub add_days_to_date {
    my ($year, $month, $day, $delta_days) = @_;

    my ($y, $m, $d) = ($year, $month, $day);

    for (1 .. $delta_days) {
        $d++;
        my $last_day = days_in_month($y, $m);
        if ($d > $last_day) {
            $d = 1;
            $m++;
            if ($m > 12) {
                $m = 1;
                $y++;
            }
        }
    }

    return ($y, $m, $d);
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

sub swiss_eph_missing_message {
    my $detail = defined $SWISSEPH_LOAD_ERROR ? $SWISSEPH_LOAD_ERROR : 'Unknown error';

    return <<"MSG";
SwissEph could not be loaded in this workspace.

This script uses the Swiss Ephemeris Perl module for Moon rise/set
calculations. The current load error was:
$detail

Once the module and native Swiss Ephemeris library are installed, run:
  perl moonrise_moonset_table.pl --lat LAT --lon LON --elev METERS

You can also point the script at ephemeris data files with:
  --ephe-path /path/to/ephe
MSG
}

sub usage {
    return <<'USAGE';
Usage:
  perl moonrise_moonset_table.pl --lat LAT --lon LON [options]

Required:
  --lat LAT              Geographic latitude in degrees
  --lon LON              Geographic longitude in degrees

Options:
  --elev METERS          Elevation above sea level (default: 0)
  --start-date YYYY-MM-DD
                         First local date to print (default: today in local timezone)
  --days N               Number of rows to print (default: 1)
  --step-days N          Day increment between rows (default: 1)
  --pressure MBAR        Atmospheric pressure for SwissEph rise/set (default: 0)
  --temperature C        Temperature for SwissEph rise/set (default: 15)
  --ephe-path PATH       Swiss Ephemeris data directory
  --tz IANA_NAME         Timezone used for local midnight and output
                         (default: TZ env var or America/Phoenix)
  --header / --no-header Print TSV header row (default: header)
  --help                 Show this help text

Output:
  date<TAB>moonrise<TAB>moonset

Notes:
  Each day is searched starting at midnight in the selected local timezone.
  If the next Moon rise or set falls outside that local-date window, the
  script prints "None in window".

Example:
  perl moonrise_moonset_table.pl --lat 33.4484 --lon -112.0740 --elev 331 --days 7
  perl moonrise_moonset_table.pl --lat 40.7128 --lon -74.0060 --tz America/New_York --days 7
USAGE
}
