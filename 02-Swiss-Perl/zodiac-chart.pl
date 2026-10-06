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
use utf8;
use SwissEph qw(:all);
use JSON::PP qw(decode_json encode_json);
use POSIX qw(tzset isfinite);
use Time::Local qw(timegm_posix);
use Scalar::Util qw(looks_like_number);

# PHP sends one JSON object on stdin. Stdout is always one JSON object.
my @sign_names = qw(Aries Taurus Gemini Cancer Leo Virgo Libra Scorpio Sagittarius Capricorn Aquarius Pisces);
my @sign_symbols = qw(♈ ♉ ♊ ♋ ♌ ♍ ♎ ♏ ♐ ♑ ♒ ♓);
my @bodies = (
    [SE_SUN,     'sun',     'Sun',     '☉'],
    [SE_MOON,    'moon',    'Moon',    '☽'],
    [SE_MERCURY, 'mercury', 'Mercury', '☿'],
    [SE_VENUS,   'venus',   'Venus',   '♀'],
    [SE_EARTH,   'earth',   'Earth',   '⊕'],
    [SE_MARS,    'mars',    'Mars',    '♂'],
    [SE_JUPITER, 'jupiter', 'Jupiter', '♃'],
    [SE_SATURN,  'saturn',  'Saturn',  '♄'],
    [SE_URANUS,  'uranus',  'Uranus',  '♅'],
    [SE_NEPTUNE, 'neptune', 'Neptune', '♆'],
    [SE_PLUTO,   'pluto',   'Pluto',   '♇'],
);

sub reject {
    my ($code, $message) = @_;
    die { code => $code, message => $message };
}

sub number {
    my ($value, $name, $min, $max) = @_;
    reject('invalid_input', "$name must be a number between $min and $max.")
        if !defined($value) || ref($value) || !looks_like_number($value)
        || !isfinite(0 + $value) || $value < $min || $value > $max;
    return 0 + $value;
}

sub text {
    my ($value, $name) = @_;
    reject('invalid_input', "$name must be a nonempty string.")
        if !defined($value) || ref($value) || !length($value);
    return $value;
}

sub read_request {
    reject('invalid_input', 'Send a JSON object on standard input; command-line arguments are not supported.') if @ARGV;
    my $cgi = exists $ENV{GATEWAY_INTERFACE};
    my $length;
    if ($cgi) {
        reject('method_not_allowed', 'Use POST with a JSON body.') if ($ENV{REQUEST_METHOD} // '') ne 'POST';
        reject('unsupported_media_type', 'Content-Type must be application/json.')
            if ($ENV{CONTENT_TYPE} // '') !~ /\Aapplication\/json(?:\s*;\s*charset\s*=\s*(?:utf-8|"utf-8"))?\s*\z/i;
        reject('length_required', 'Content-Length is required.') if !exists $ENV{CONTENT_LENGTH};
        reject('invalid_input', 'Invalid Content-Length.') if $ENV{CONTENT_LENGTH} !~ /\A[0-9]{1,8}\z/;
        $length = 0 + $ENV{CONTENT_LENGTH};
        reject('payload_too_large', 'JSON input exceeds 8192 bytes.') if $length > 8192;
        my $token = $ENV{ZODIAC_CGI_TOKEN} // '';
        if (length $token) {
            my $provided = $ENV{HTTP_X_ZODIAC_TOKEN} // '';
            my $provided_length = length($provided);
            my $difference = length($token) ^ $provided_length;
            for my $i (0..length($token) - 1) {
                # ASCII '0' is a real byte, despite being false in Perl.
                my $provided_byte = $i < $provided_length ? ord(substr($provided, $i, 1)) : 0;
                $difference |= ord(substr($token, $i, 1)) ^ $provided_byte;
            }
            reject('unauthorized', 'CGI authentication required.') if $difference;
        }
    }
    binmode STDIN, ':raw';
    my $json = '';
    # Bound the read itself, rather than slurping unbounded input from PHP.
    my $limit = $cgi ? $length : 8193;
    while (length($json) < $limit) {
        my $count = read(STDIN, my $chunk, $limit - length($json));
        reject('invalid_input', 'Unable to read JSON input.') if !defined $count;
        last if !$count;
        $json .= $chunk;
        reject('payload_too_large', 'JSON input exceeds 8192 bytes.') if length($json) > 8192;
    }
    reject('invalid_input', 'Incomplete JSON body.') if $cgi && length($json) != $length;
    my $input = eval { JSON::PP->new->utf8->max_depth(4)->decode($json) };
    reject('invalid_input', 'Input must be a valid JSON object.') if $@ || ref($input) ne 'HASH';
    my %allowed = map { $_ => 1 } qw(date time timezone latitude longitude house_system width utc_offset_seconds);
    reject('invalid_input', "Unknown input field: $_.") for grep { !$allowed{$_} } sort keys %$input;
    return $input;
}

sub iso_time {
    my ($tm) = @_;
    return sprintf('%04d-%02d-%02dT%02d:%02d:%02d',
        $tm->[5] + 1900, $tm->[4] + 1, $tm->[3], @$tm[2, 1, 0]);
}

sub offset_text {
    my ($offset) = @_;
    my $n = abs($offset);
    my $result = sprintf('%s%02d:%02d', $offset < 0 ? '-' : '+', int($n / 3600), int(($n % 3600) / 60));
    $result .= sprintf(':%02d', $n % 60) if $n % 60;
    return $result;
}

sub resolve_time {
    my ($input) = @_;
    my $zone = text($input->{timezone}, 'timezone');
    reject('invalid_input', 'timezone must be an IANA timezone name, for example America/Phoenix or UTC.')
        if $zone !~ /\A[A-Za-z0-9_+-]+(?:\/[A-Za-z0-9_+-]+)*\z/
        || $zone =~ /\A(?:posix|right)(?:\/|\z)/ || !-f "/usr/share/zoneinfo/$zone";
    # Use the OS timezone database, including DST; never the server's default TZ.
    $ENV{TZ} = ":/usr/share/zoneinfo/$zone";
    tzset();
    my $date = text($input->{date}, 'date');
    my $time = text($input->{time}, 'time');
    reject('invalid_input', 'date must be Gregorian YYYY-MM-DD, with year 0001 through 9999.')
        if $date !~ /\A([0-9]{4})-([0-9]{2})-([0-9]{2})\z/ || $1 == 0;
    my ($year, $month, $day) = (0 + $1, 0 + $2, 0 + $3);
    reject('invalid_input', 'time must be HH:MM or HH:MM:SS, from 00:00:00 through 23:59:59.')
        if $time !~ /\A([0-9]{2}):([0-9]{2})(?::([0-9]{2}))?\z/;
    my ($hour, $minute, $second) = (0 + $1, 0 + $2, defined($3) ? 0 + $3 : 0);
    reject('invalid_input', 'Invalid calendar date or time.')
        if $month < 1 || $month > 12 || $day < 1 || $day > 31 || $hour > 23 || $minute > 59 || $second > 59;
    my @wall = ($second, $minute, $hour, $day, $month - 1, $year - 1900);
    my $naive = eval { timegm_posix(@wall) };
    reject('invalid_input', 'Invalid calendar date or time.') if $@;
    my @check = gmtime($naive);
    reject('invalid_input', 'Invalid calendar date or time.') if join(',', @check[0..5]) ne join(',', @wall);

    # Gather nearby UTC offsets, then round-trip every candidate. A spring gap
    # gives no matches, and an autumn repeated hour gives two, never a guess.
    my %offsets;
    for (my $h = -48; $h <= 48; $h += 6) {
        my $epoch = $naive + $h * 3600;
        my @local = localtime($epoch);
        $offsets{timegm_posix(@local[0..5]) - $epoch} = 1;
    }
    my @matches;
    for my $offset (sort { $a <=> $b } keys %offsets) {
        my $epoch = $naive - $offset;
        my @local = localtime($epoch);
        push @matches, { epoch => $epoch, offset => 0 + $offset, tm => \@local }
            if join(',', @local[0..5]) eq join(',', @wall);
    }
    reject('nonexistent_local_time', 'This local date/time does not exist in the selected timezone (a DST gap or skipped date).') if !@matches;
    if (exists $input->{utc_offset_seconds}) {
        my $offset = number($input->{utc_offset_seconds}, 'utc_offset_seconds', -86400, 86400);
        reject('invalid_input', 'utc_offset_seconds must be an integer.') if int($offset) != $offset;
        @matches = grep { $_->{offset} == $offset } @matches;
        reject('invalid_input', 'utc_offset_seconds does not match this local date/time in the selected timezone.') if !@matches;
    }
    reject('ambiguous_local_time', 'This local date/time occurs twice. Supply utc_offset_seconds from PHP to select the intended instant.') if @matches > 1;
    my $chosen = $matches[0];
    my @utc = gmtime($chosen->{epoch});
    return {
        date => $date, time => sprintf('%02d:%02d:%02d', $hour, $minute, $second), timezone => $zone,
        local_datetime => iso_time($chosen->{tm}) . offset_text($chosen->{offset}),
        utc_datetime => iso_time(\@utc) . 'Z', utc_offset_seconds => $chosen->{offset},
        unix_timestamp => $chosen->{epoch}, utc_parts => \@utc,
    };
}

sub sign_position {
    my ($longitude) = @_;
    my $index = int($longitude / 30);
    return { index => $index, name => $sign_names[$index], symbol => $sign_symbols[$index], degree => $longitude - $index * 30 };
}

sub chart_offset {
    my ($longitude, $origin) = @_;
    return swe_degnorm($longitude - $origin);
}

sub segment {
    my ($start, $end, $width) = @_;
    return {
        start_offset_deg => $start, end_offset_deg => $end,
        x_start_fraction => $start / 360, x_end_fraction => $end / 360,
        x_start_px => $start / 360 * $width, x_end_px => $end / 360 * $width,
        width_px => ($end - $start) / 360 * $width,
    };
}

sub calculate {
    my ($input) = @_;
    my $latitude = number($input->{latitude}, 'latitude', -90, 90);
    reject('invalid_input', 'latitude must be strictly between -90 and 90 for houses.') if abs($latitude) == 90;
    my $longitude = number($input->{longitude}, 'longitude', -180, 180);
    my $width = exists($input->{width}) ? number($input->{width}, 'width', 1, 100000) : 1200;
    my $system = exists($input->{house_system}) ? text($input->{house_system}, 'house_system') : 'E';
    reject('invalid_input', 'house_system must be E (equal), P (Placidus), or W (whole sign).') if $system !~ /\A[EPW]\z/;
    my $instant = resolve_time($input);
    my $path = $ENV{SE_EPHE_PATH};
    reject('configuration_error', 'Set SE_EPHE_PATH to an existing absolute ephemeris data directory.')
        if !defined($path) || $path !~ m{\A/} || !-d $path;
    swe_set_ephe_path($path);
    my @utc = @{$instant->{utc_parts}};
    my $jd = swe_utc_to_jd($utc[5] + 1900, $utc[4] + 1, $utc[3], $utc[2], $utc[1], $utc[0], SE_GREG_CAL);
    reject('calculation_error', 'Swiss Ephemeris could not convert UTC to Julian day.') if $jd->{retval} < 0;
    delete $instant->{utc_parts};
    $instant->{julian_day_ut1} = $jd->{tjd_ut};
    $instant->{julian_day_tt} = $jd->{tjd_et};

    # ex2 exposes the error code so a Placidus failure cannot silently substitute
    # Porphyry houses at polar latitudes.
    my $raw = swe_houses_ex2($jd->{tjd_ut}, 0, $latitude, $longitude, $system);
    reject('house_calculation_error', 'Requested houses cannot be calculated at this location/time. Try equal or whole-sign houses.') if $raw->{retval} < 0;
    my @cusps = map { swe_degnorm($_) } @{$raw->{cusps}}[1..12];
    my $origin = $cusps[0];
    my @offsets = map { chart_offset($_, $origin) } @cusps;
    push @offsets, 360;
    my @houses;
    for my $i (0..11) {
        reject('house_calculation_error', 'House cusps do not form an increasing ecliptic ruler at this location/time.')
            if $offsets[$i + 1] <= $offsets[$i];
        push @houses, {
            number => $i + 1, cusp_longitude_deg => $cusps[$i],
            end_longitude_deg => $cusps[($i + 1) % 12], span_deg => $offsets[$i + 1] - $offsets[$i],
            sign => sign_position($cusps[$i]), %{segment($offsets[$i], $offsets[$i + 1], $width)},
        };
    }
    my @zodiac;
    for my $i (0..11) {
        my $start = chart_offset($i * 30, $origin);
        my $end = $start + 30;
        my @segments = $end <= 360 ? (segment($start, $end, $width))
            : (segment(0, $end - 360, $width), segment($start, 360, $width));
        push @zodiac, {
            index => $i, name => $sign_names[$i], symbol => $sign_symbols[$i],
            start_longitude_deg => $i * 30, end_longitude_deg => (($i + 1) * 30) % 360,
            span_deg => 30, segments => \@segments,
        };
    }

    my @planets;
    for my $body (@bodies) {
        my ($id, $key, $name, $symbol) = @$body;
        my $is_earth = $id == SE_EARTH;
        my $flags = SEFLG_SWIEPH | SEFLG_SPEED;
        $flags |= SEFLG_HELCTR if $is_earth;
        my $calc = swe_calc_ut($jd->{tjd_ut}, $id, $flags);
        reject('calculation_error', "Swiss Ephemeris could not calculate $name for this date.") if $calc->{retval} < 0;
        reject('ephemeris_unavailable', "Swiss ephemeris files for $name are unavailable for this date; check SE_EPHE_PATH. Moshier fallback is disabled.")
            if !($calc->{retval} & SEFLG_SWIEPH);
        my ($lon, $lat, $distance, $speed) = @{$calc->{xx}}[0..3];
        $lon = swe_degnorm($lon);
        my ($house, $offset);
        if (!$is_earth) {
            $offset = chart_offset($lon, $origin);
            for my $i (0..11) {
                $house = $i + 1 if $offset >= $offsets[$i] && $offset < $offsets[$i + 1];
            }
        }
        push @planets, {
            key => $key, name => $name, symbol => $symbol, swiss_ephemeris_id => $id,
            longitude_deg => $lon, latitude_deg => $lat, distance_au => $distance,
            longitude_speed_deg_per_day => $speed, retrograde => $speed < 0 ? JSON::PP::true : JSON::PP::false,
            reference_frame => $is_earth ? 'heliocentric' : 'geocentric', sign => sign_position($lon),
            plot_on_chart => $is_earth ? JSON::PP::false : JSON::PP::true,
            house_number => $house, chart_offset_deg => $offset,
            x_fraction => defined($offset) ? $offset / 360 : undef,
            x_px => defined($offset) ? $offset / 360 * $width : undef,
        };
    }
    return {
        schema_version => 1, instant => $instant,
        location => { latitude => $latitude, longitude => $longitude },
        calculation => {
            zodiac => 'tropical', coordinate_system => 'ecliptic_of_date', units => 'degrees',
            planet_reference_frame => 'geocentric', ephemeris => 'Swiss Ephemeris',
            versions => swe_version(), house_system => $system, house_system_name => swe_house_name($system),
            house_assignment => 'ecliptic_longitude_between_cusps',
            earth_note => 'Earth has no geocentric direction. Its longitude is heliocentric and must not be plotted among geocentric planets or assigned to a terrestrial house.',
        },
        chart => {
            width_px => $width, origin_longitude_deg => $origin, origin => 'house_1_cusp',
            direction => 'increasing_ecliptic_longitude', span_deg => 360, pixels_per_degree => $width / 360,
        },
        angles => { ascendant_longitude_deg => swe_degnorm($raw->{asc}), midheaven_longitude_deg => swe_degnorm($raw->{mc}) },
        zodiac => \@zodiac, houses => \@houses, planets => \@planets,
    };
}

binmode STDOUT, ':raw';
my $output = eval {
    local $SIG{ALRM} = sub { reject('timeout', 'Calculation timed out.'); };
    alarm 15;
    my $result = calculate(read_request());
    alarm 0;
    $result;
};
my $error = $@;
alarm 0;
swe_close();
my %statuses = (
    invalid_input => 400, nonexistent_local_time => 400, ambiguous_local_time => 400,
    house_calculation_error => 422, method_not_allowed => 405, unsupported_media_type => 415,
    length_required => 411, payload_too_large => 413, unauthorized => 401, timeout => 504,
);
my $status = $error ? (ref($error) eq 'HASH' ? ($statuses{$error->{code}} // 500) : 500) : 200;
if (exists $ENV{GATEWAY_INTERFACE}) {
    my %labels = (200 => 'OK', 400 => 'Bad Request', 401 => 'Unauthorized', 405 => 'Method Not Allowed',
        411 => 'Length Required', 413 => 'Content Too Large', 415 => 'Unsupported Media Type',
        422 => 'Unprocessable Content', 500 => 'Internal Server Error', 504 => 'Gateway Timeout');
    print "Status: $status $labels{$status}\r\n";
    print "Allow: POST\r\n" if $status == 405;
    print "Content-Type: application/json; charset=UTF-8\r\nCache-Control: no-store\r\nX-Content-Type-Options: nosniff\r\n\r\n";
}
if ($error) {
    my $known = ref($error) eq 'HASH';
    print STDERR "zodiac-chart: $error" if !$known;
    print STDERR "zodiac-chart: $error->{code}\n" if $known && $status >= 500;
    print encode_json({ error => {
        code => $known ? $error->{code} : 'internal_error',
        message => $known ? $error->{message} : 'Unexpected calculation failure; check the server log.',
    } }), "\n";
    exit 1;
}
print encode_json($output), "\n";
