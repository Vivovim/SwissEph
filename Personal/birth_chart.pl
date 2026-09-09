#!/usr/bin/perl

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

my %opt = (
    elev         => 0,
    ephe_path    => $ENV{SE_EPHE_PATH},
    house_system => 'P',
);

GetOptions(
    'timestamp=s'    => \$opt{timestamp},
    'lat=f'          => \$opt{lat},
    'lon=f'          => \$opt{lon},
    'elev=f'         => \$opt{elev},
    'ephe-path=s'    => \$opt{ephe_path},
    'house-system=s' => \$opt{house_system},
    'help|h'         => \$opt{help},
) or die usage();

if ($opt{help}) {
    print usage();
    exit 0;
}

die swiss_eph_missing_message()
    if defined $SWISSEPH_LOAD_ERROR;

for my $required (qw(timestamp lat lon)) {
    die usage() unless defined $opt{$required};
}

die "--lat must be between -90 and 90\n"
    if $opt{lat} < -90 || $opt{lat} > 90;

die "--lon must be between -180 and 180\n"
    if $opt{lon} < -180 || $opt{lon} > 180;

$opt{house_system} = uc substr($opt{house_system}, 0, 1);
my $house_system_name = eval { SwissEph::swe_house_name($opt{house_system}) };
die "--house-system must be a valid Swiss Ephemeris house system code, for example P or E\n"
    unless defined $house_system_name && length $house_system_name;

if (defined $opt{ephe_path} && length $opt{ephe_path}) {
    SwissEph::swe_set_ephe_path($opt{ephe_path});
}

my $epoch = parse_timestamp($opt{timestamp});
my $local = localtime($epoch);
my $utc = gmtime($epoch);
my $jd = utc_to_jd($utc);

my $planet_iflag = base_iflag(\%opt);
my $house_iflag = 0;

my $houses = call_houses_ex(
    $jd->{tjd_ut},
    $house_iflag,
    $opt{lat},
    $opt{lon},
    $opt{house_system},
);

my $ecl_nut = call_calc_ut(
    $jd->{tjd_ut},
    swe_const('SE_ECL_NUT'),
    $planet_iflag,
);

my $eps_true = $ecl_nut->{xx}->[0];

my @bodies = (
    [ swe_const('SE_SUN'),     'Sun'     ],
    [ swe_const('SE_MOON'),    'Moon'    ],
    [ swe_const('SE_MERCURY'), 'Mercury' ],
    [ swe_const('SE_VENUS'),   'Venus'   ],
    [ swe_const('SE_MARS'),    'Mars'    ],
    [ swe_const('SE_JUPITER'), 'Jupiter' ],
    [ swe_const('SE_SATURN'),  'Saturn'  ],
    [ swe_const('SE_URANUS'),  'Uranus'  ],
    [ swe_const('SE_NEPTUNE'), 'Neptune' ],
    [ swe_const('SE_PLUTO'),   'Pluto'   ],
);

say 'Birth Chart';
say '-----------';
say "Timestamp input: $opt{timestamp}";
say "Timestamp ($LOCAL_TZ): " . $local->strftime('%Y-%m-%d %H:%M:%S');
say 'Timestamp (UTC): ' . $utc->strftime('%Y-%m-%d %H:%M:%S');
say sprintf(
    'Location: lat %.6f, lon %.6f, elev %.1f m',
    $opt{lat},
    $opt{lon},
    $opt{elev},
);
say 'Zodiac: Tropical';
say "House system: $house_system_name ($opt{house_system})";
say 'Ephemeris mode: ' . ephemeris_mode_label(\%opt);
say '';

my $asc = describe_longitude(effective_ascendant_longitude($houses, $opt{house_system}));
say sprintf(
    'Ascendant: %s %s (%s)',
    $asc->{sign},
    $asc->{degree_text},
    $asc->{absolute_text},
);
say '';
say sprintf(
    '%-9s  %-11s  %-13s  %-5s  %s',
    'Body',
    'Sign',
    'Degree',
    'House',
    'Longitude',
);
say '-' x 64;

for my $body (@bodies) {
    my ($body_id, $name) = @$body;
    my $calc = call_calc_ut($jd->{tjd_ut}, $body_id, $planet_iflag);
    my ($lon, $lat) = @{ $calc->{xx} }[0, 1];
    my $house_pos = call_house_pos(
        $houses->{armc},
        $opt{lat},
        $eps_true,
        $opt{house_system},
        $lon,
        $lat,
    );
    # Prefer cusp-based house membership for display so cusp-edge cases
    # match the chart wheel the user is reading from.
    my $display_house = house_number_from_cusps($lon, $houses->{cusps}, $opt{house_system})
        // $house_pos->{ihno};
    my $pos = describe_longitude($lon);

    say sprintf(
        '%-9s  %-11s  %-13s  %-5d  %s',
        $name,
        $pos->{sign},
        $pos->{degree_text},
        $display_house,
        $pos->{absolute_text},
    );
}

SwissEph::swe_close();

sub parse_timestamp {
    my ($input) = @_;

    return int($input)
        if defined $input && $input =~ /\A-?\d+(?:\.\d+)?\z/;

    my $normalized = normalize_datetime($input);
    my ($year, $month, $day, $hour, $minute, $second, $tz) =
        $normalized =~ /\A(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(Z|[+-]\d{2}:?\d{2})?\z/
        or die "Unsupported --timestamp format. Use Unix epoch seconds or ISO-8601 like 1990-01-01T12:34:56, 1990-01-01T12:34:56Z, or 1990-01-01T12:34:56-0700\n";

    if (!defined $tz) {
        return timelocal($second, $minute, $hour, $day, $month - 1, $year);
    }

    my $epoch = timegm($second, $minute, $hour, $day, $month - 1, $year);
    return $epoch if !defined $tz || $tz eq 'Z';

    my ($sign, $tz_hour, $tz_min) = $tz =~ /\A([+-])(\d{2}):?(\d{2})\z/;
    my $offset = ($tz_hour * 3600) + ($tz_min * 60);

    return $sign eq '+'
        ? $epoch - $offset
        : $epoch + $offset;
}

sub normalize_datetime {
    my ($input) = @_;

    if ($input =~ /\A(\d{4}-\d{2}-\d{2})[T ](\d{1,2}):(\d{2}):(\d{2})(Z|[+-]\d{2}:?\d{2})?\z/) {
        return sprintf('%sT%02d:%02d:%02d%s', $1, $2, $3, $4, defined $5 ? $5 : q{});
    }

    return $input;
}

sub utc_to_jd {
    my ($utc) = @_;

    my $raw = SwissEph::swe_utc_to_jd(
        $utc->year,
        $utc->mon,
        $utc->mday,
        $utc->hour,
        $utc->min,
        $utc->sec + 0,
        swe_const('SE_GREG_CAL'),
    );

    if (ref($raw) eq 'HASH') {
        die "SwissEph UTC->JD failed: $raw->{serr}\n"
            if defined $raw->{serr} && length $raw->{serr};
        return $raw;
    }

    if (ref($raw) eq 'ARRAY' && @$raw >= 2) {
        return {
            tjd_et => $raw->[0],
            tjd_ut => $raw->[1],
        };
    }

    die "Unexpected SwissEph UTC->JD result\n";
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

sub house_number_from_pos {
    my ($dhpos) = @_;

    my $house = int($dhpos);
    $house = 1 if $house < 1;
    $house = 12 if $house > 12;
    return $house;
}

sub effective_ascendant_longitude {
    my ($houses, $house_system) = @_;

    my $asc = normalize_360($houses->{asc});
    my $cusp1 = first_house_cusp_longitude($houses);
    return $asc unless defined $cusp1;

    # In Placidus, cusp 1 and the Ascendant should coincide. If they diverge,
    # prefer cusp 1 as a safer display value.
    if (uc($house_system) eq 'P' && angular_separation($asc, $cusp1) > (1 / 60)) {
        return $cusp1;
    }

    return $asc;
}

sub first_house_cusp_longitude {
    my ($houses) = @_;

    return unless ref($houses) eq 'HASH';
    return unless ref($houses->{cusps}) eq 'ARRAY';
    return unless defined $houses->{cusps}->[1];

    return normalize_360($houses->{cusps}->[1]);
}

sub house_number_from_cusps {
    my ($longitude, $cusps, $house_system) = @_;

    return if !defined $house_system || uc($house_system) eq 'G';
    return unless ref($cusps) eq 'ARRAY' && @$cusps >= 13;

    my $point = normalize_360($longitude);

    for my $house (1 .. 12) {
        my $start = $cusps->[$house];
        my $end = $cusps->[$house == 12 ? 1 : $house + 1];
        next unless defined $start && defined $end;

        my $span = forward_arc($start, $end);
        my $offset = forward_arc($start, $point);

        return $house if $offset < $span || abs($offset - $span) < 1e-7;
    }

    return;
}

sub forward_arc {
    my ($start, $end) = @_;
    return normalize_360($end - $start);
}

sub angular_separation {
    my ($a, $b) = @_;

    my $delta = abs(normalize_360($a) - normalize_360($b));
    return $delta > 180 ? 360 - $delta : $delta;
}

sub describe_longitude {
    my ($longitude) = @_;

    my @signs = qw(Aries Taurus Gemini Cancer Leo Virgo Libra Scorpio Sagittarius Capricorn Aquarius Pisces);
    my $normalized = normalize_360($longitude);
    my $sign_index = int($normalized / 30);
    my $in_sign = $normalized - ($sign_index * 30);

    my $degree = int($in_sign);
    my $minutes_float = ($in_sign - $degree) * 60;
    my $minute = int($minutes_float);
    my $second = int(((($minutes_float - $minute) * 60) + 0.5));

    if ($second == 60) {
        $second = 0;
        $minute++;
    }
    if ($minute == 60) {
        $minute = 0;
        $degree++;
    }
    if ($degree == 30) {
        $degree = 0;
        $sign_index = ($sign_index + 1) % 12;
    }

    return {
        sign          => $signs[$sign_index],
        degree_text   => sprintf('%02dd %02dm %02ds', $degree, $minute, $second),
        absolute_text => sprintf('%s %02dd %02dm %02ds', $signs[$sign_index], $degree, $minute, $second),
    };
}

sub normalize_360 {
    my ($angle) = @_;
    $angle -= 360 * floor($angle / 360);
    $angle += 360 if $angle < 0;
    return $angle;
}

sub base_iflag {
    my ($opt) = @_;
    return swe_const('SEFLG_SWIEPH') if defined $opt->{ephe_path} && length $opt->{ephe_path};
    return swe_const('SEFLG_MOSEPH');
}

sub set_timezone {
    my ($tz) = @_;
    $ENV{TZ} = $tz;
    tzset();
}

sub ephemeris_mode_label {
    my ($opt) = @_;
    return 'Swiss Ephemeris files' if defined $opt->{ephe_path} && length $opt->{ephe_path};
    return 'Moshier fallback';
}

sub swe_const {
    my ($name) = @_;

    no strict 'refs';
    my $full_name = "SwissEph::$name";
    die "SwissEph constant $name is not available\n" unless defined &{$full_name};
    return &{$full_name}();
}

sub swiss_eph_missing_message {
    return <<'MSG';
SwissEph could not be loaded.

This script expects the Perl SwissEph bindings to be installed and available.
MSG
}

sub usage {
    return <<'USAGE';
Usage:
  perl birth_chart.pl --timestamp 631152000 --lat 40.7128 --lon -74.0060 [--elev 10] [--house-system E]

Required:
  --timestamp   Unix epoch seconds, or ISO-8601 like 1990-01-01T12:34:56
                Bare datetimes are interpreted as America/Phoenix local time.
                Add Z or an explicit offset for UTC / fixed-offset input.
  --lat         Latitude in decimal degrees
  --lon         Longitude in decimal degrees (east positive, west negative)

Optional:
  --elev        Elevation in meters above sea level, defaults to 0
  --ephe-path   Path to Swiss Ephemeris data files; defaults to $SE_EPHE_PATH
  --house-system
                Swiss Ephemeris house system code, defaults to P
                Use E for Equal houses, P for Placidus, etc.

Notes:
  The chart uses a tropical zodiac.
USAGE
}
