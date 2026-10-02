#!/usr/bin/perl -T


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



package MoonRiseCGI;
use strict;
use warnings;

# CGI must stay in taint mode. Do not use env-based Perl/module paths.
BEGIN {
    die "Run this CGI using perl -T.\n" unless ${^TAINT};
    $ENV{PATH} = '/usr/bin:/bin';
    delete @ENV{qw(IFS CDPATH ENV BASH_ENV PERL5LIB PERLLIB PERL5OPT
        LD_LIBRARY_PATH LD_PRELOAD DYLD_LIBRARY_PATH DYLD_INSERT_LIBRARIES
        TZ TZDIR SE_EPHE_PATH SE_STAR_PATH SE_JPL_FILE)};
}

# Configuration: edit these server-owned values before deployment.
# Generate shared_key with: openssl rand -hex 32
# Store that key in server-side PHP configuration; NEVER send it to a browser.
our %CONFIG = (
    db_host        => 'localhost',
    db_port        => 3306,
    db_name        => '',
    db_user        => '',
    db_password    => '',
    shared_key     => '',
    allowed_origin => 'https://astro.ctopher.me',
    require_https  => 1,
    max_body_bytes => 1024,
    timeout_seconds => 15,
    zoneinfo_dir   => '/usr/share/zoneinfo',
    ephemeris_path => '', # Empty uses Moshier; otherwise an absolute data directory.
);

use JSON::PP ();
use Digest::SHA qw(sha256);
use POSIX qw(tzset strftime floor isfinite);
use Time::Local qw(timelocal_posix timegm_posix);

main() unless caller;

sub main {
    my ($result, $error);
    {
        local $SIG{ALRM} = sub { die "MoonRise request timed out.\n" };
        my $ok = eval {
            alarm $CONFIG{timeout_seconds};
            $result = handle_request();
            alarm 0;
            1;
        };
        $error = $@ unless $ok;
        alarm 0;
    }
    if ($error) {
        if (ref($error) eq 'MoonRiseCGI::HTTPError') {
            send_json($error->{status}, { error => $error->{message} });
        } else {
            # Details go only to the server log, never into a public response.
            my $detail = "$error";
            $detail =~ s/[\x00-\x1f\x7f]+/ /g;
            warn "MoonRise CGI: $detail\n";
            send_json(500, { error => 'Unable to calculate moonrise and moonset. Please try again later.' });
        }
        return;
    }
    send_json(200, $result);
}

sub handle_request {
    reject(405, 'Use POST with a JSON body.')
        unless ($ENV{REQUEST_METHOD} // '') eq 'POST';
    reject(403, 'HTTPS is required.') if $CONFIG{require_https}
        && ($ENV{HTTPS} // '') !~ /\A(?:on|1)\z/i;

    # Additional browser checks. Authentication below is required even if these pass.
    reject(403, 'This origin is not allowed.') if exists $ENV{HTTP_ORIGIN}
        && $ENV{HTTP_ORIGIN} ne $CONFIG{allowed_origin};
    reject(403, 'Cross-site requests are not allowed.')
        if ($ENV{HTTP_SEC_FETCH_SITE} // '') eq 'cross-site';

    die "Configure shared_key with 64 lowercase hexadecimal characters.\n"
        unless $CONFIG{shared_key} =~ /\A[a-f0-9]{64}\z/;
    my $provided = $ENV{HTTP_X_MOONRISE_KEY} // '';
    reject(403, 'Access denied.') unless $provided =~ /\A[a-f0-9]{64}\z/
        && constant_time_equal($provided, $CONFIG{shared_key});

    reject(400, 'Send the ID only in the JSON body.') if length($ENV{QUERY_STRING} // '');
    reject(400, 'Transfer-Encoding is not supported.') if length($ENV{HTTP_TRANSFER_ENCODING} // '');
    reject(415, 'Content-Type must be application/json.')
        unless ($ENV{CONTENT_TYPE} // '') =~ /\Aapplication\/json(?:\s*;\s*charset\s*=\s*(?:utf-8|"utf-8"))?\s*\z/i;
    reject(415, 'Compressed request bodies are not supported.')
        if length($ENV{HTTP_CONTENT_ENCODING} // '')
            && lc($ENV{HTTP_CONTENT_ENCODING}) ne 'identity';

    reject(411, 'Content-Length is required.') unless exists $ENV{CONTENT_LENGTH};
    my ($length) = $ENV{CONTENT_LENGTH} =~ /\A([0-9]{1,10})\z/;
    reject(400, 'Invalid Content-Length.') unless defined $length;
    reject(413, 'JSON body is too large.') if $length > $CONFIG{max_body_bytes};
    reject(400, 'JSON body is empty.') if $length == 0;

    binmode STDIN, ':raw' or die "Cannot read CGI input.\n";
    my $body = '';
    while (length($body) < $length) {
        my $read = read(STDIN, my $chunk, $length - length($body));
        die "Cannot read CGI input: $!\n" unless defined $read;
        reject(400, 'Incomplete JSON body.') if $read == 0;
        $body .= $chunk;
    }
    my $payload = eval {
        JSON::PP->new->utf8->max_size($CONFIG{max_body_bytes})->max_depth(3)->decode($body);
    };
    reject(400, 'Invalid JSON body.') if $@;
    reject(400, 'Send one JSON object containing only id.')
        unless ref($payload) eq 'HASH' && keys(%$payload) == 1 && exists $payload->{id};

    my $id = validated_id($payload->{id});
    my $city = lookup_city($id);
    reject(404, 'City ID was not found.') unless $city;
    my $coordinates = validated_location($city, $id);
    my $events = calculate_events($coordinates, time);
    return {
        id        => 0 + $id,
        city      => $city->{city},
        latitude  => $coordinates->{latitude},
        longitude => $coordinates->{longitude},
        timezone  => $coordinates->{timezone},
        %$events,
    };
}

sub validated_id {
    my ($value) = @_;
    reject(400, 'id must be a positive integer.') unless defined $value && !ref($value);
    # Capture only this tightly validated value to untaint it. Never untaint the body.
    my ($id) = "$value" =~ /\A([1-9][0-9]{0,9})\z/;
    reject(400, 'id must be between 1 and 4294967295.')
        unless defined($id) && $id <= 4294967295;
    return $id;
}

sub lookup_city {
    my ($id) = @_;
    die "Configure the MySQL connection settings first.\n"
        if $CONFIG{db_name} eq 'your_database' || $CONFIG{db_user} eq 'your_user'
            || $CONFIG{db_password} eq 'your_password';
    # Perl uses DBI/DBD::mysql; mysqli is a PHP extension.
    require DBI;
    my $dsn = "DBI:mysql:database=$CONFIG{db_name};host=$CONFIG{db_host};port=$CONFIG{db_port}";
    my $dbh = DBI->connect($dsn, $CONFIG{db_user}, $CONFIG{db_password}, {
        RaiseError => 1, PrintError => 0, AutoCommit => 1,
        mysql_enable_utf8mb4 => 1, mysql_connect_timeout => 5,
        TaintIn => 1, TaintOut => 1,
    });
    my ($row, $error);
    my $ok = eval {
        $row = $dbh->selectrow_hashref(
            'SELECT `id`, `city`, `latitude`, `longitude`, `tz` FROM `Zones` WHERE `id` = ?',
            undef, $id,
        );
        1;
    };
    $error = $@ unless $ok;
    $dbh->disconnect;
    die $error unless $ok;
    return $row;
}

sub validated_location {
    my ($row, $wanted_id) = @_;
    die "Invalid location record.\n" unless ref($row) eq 'HASH';
    my ($id) = defined($row->{id}) && !ref($row->{id})
        ? "$row->{id}" =~ /\A([1-9][0-9]{0,9})\z/ : ();
    die "Invalid location ID in database.\n" unless defined($id) && $id eq $wanted_id;
    die "Invalid city name in database.\n" unless defined($row->{city})
        && !ref($row->{city}) && length($row->{city}) > 0 && length($row->{city}) <= 255;
    my %location;
    for my $spec (['latitude', 90], ['longitude', 180]) {
        my ($field, $limit) = @$spec;
        my $raw = $row->{$field};
        my ($number) = defined($raw) && !ref($raw)
            ? "$raw" =~ /\A([+-]?[0-9]{1,3}(?:\.[0-9]{1,5})?)\z/ : ();
        die "Invalid $field in database.\n" unless defined($number) && abs($number) <= $limit;
        $location{$field} = 0 + $number;
    }
    $location{timezone} = validated_timezone($row->{tz});
    return \%location;
}

sub validated_timezone {
    my ($raw) = @_;
    die "Invalid timezone in database.\n" unless defined($raw) && !ref($raw) && length($raw) <= 64;
    # No absolute paths, dots, colons, NULs, or environment-controlled TZDIR.
    my ($timezone) = $raw =~ /\A([A-Za-z][A-Za-z0-9_+-]*(?:\/[A-Za-z0-9_+-]+)*)\z/;
    die "Unknown timezone in database.\n" unless defined($timezone)
        && -f "$CONFIG{zoneinfo_dir}/$timezone";
    return $timezone;
}

sub local_day_window {
    my ($timezone, $now) = @_;
    $ENV{TZ} = validated_timezone($timezone);
    tzset();
    my @today = localtime($now);
    my $start = timelocal_posix(0, 0, 0, $today[3], $today[4], $today[5]);
    # Advance the calendar date, then convert its midnight using timezone rules.
    # A local day may be 23 or 25 hours during daylight-saving transitions.
    my @tomorrow = gmtime(timegm_posix(0, 0, 12, $today[3], $today[4], $today[5]) + 86400);
    my $end = timelocal_posix(0, 0, 0, $tomorrow[3], $tomorrow[4], $tomorrow[5]);
    die "Invalid local-day window.\n" unless $end > $start;
    return ($start, $end, strftime('%Y-%m-%d', @today));
}

sub calculate_events {
    my ($location, $now) = @_;
    require SwissEph;
    my ($start, $end, $date) = local_day_window($location->{timezone}, $now);
    my $path = $CONFIG{ephemeris_path};
    die "Ephemeris directory must be an existing absolute directory.\n"
        if length($path) && ($path !~ m{\A/} || !-d $path);
    SwissEph::swe_set_ephe_path($path);
    SwissEph::swe_set_topo($location->{longitude}, $location->{latitude}, 0);
    my $flags = length($path) ? SwissEph::SEFLG_SWIEPH() : SwissEph::SEFLG_MOSEPH();
    my ($events, $error);
    my $ok = eval {
        $events = {
            date => $date,
            moonrise => event_in_window($start, $end, SwissEph::SE_CALC_RISE(), $flags, $location),
            moonset  => event_in_window($start, $end, SwissEph::SE_CALC_SET(), $flags, $location),
        };
        1;
    };
    $error = $@ unless $ok;
    SwissEph::swe_close();
    die $error unless $ok;
    return $events;
}

sub event_in_window {
    my ($start, $end, $event, $flags, $location) = @_;
    my $start_jd = $start / 86400 + 2440587.5;
    my $end_jd = $end / 86400 + 2440587.5;
    my $raw = SwissEph::swe_rise_trans(
        $start_jd, SwissEph::SE_MOON(), '', $flags, $event,
        [$location->{longitude}, $location->{latitude}, 0], 0, 15,
    );
    die "Unexpected SwissEph response.\n" unless ref($raw) eq 'HASH' && defined($raw->{retval});
    return undef if $raw->{retval} == -2; # Circumpolar: no event.
    die "SwissEph rise/set failed.\n" unless $raw->{retval} == 0;
    # SwissEph's Perl binding returns the event Julian day in dret.
    my $jd = $raw->{dret};
    die "SwissEph returned an invalid event time.\n"
        unless defined($jd) && !ref($jd) && isfinite($jd) && $jd >= $start_jd;
    return undef if $jd >= $end_jd; # The next event belongs to a later local day.
    my $epoch = floor(($jd - 2440587.5) * 86400 + 0.5);
    $epoch = $end - 1 if $epoch >= $end; # Keep rounding within the selected date.
    my $timestamp = strftime('%Y-%m-%dT%H:%M:%S%z', localtime($epoch));
    $timestamp =~ s/([+-][0-9]{2})([0-9]{2})\z/$1:$2/;
    return $timestamp;
}

sub constant_time_equal {
    my ($left, $right) = @_;
    # Fixed-length binary digest comparison avoids an early exit on a prefix match.
    my $difference = sha256($left) ^ sha256($right);
    my $mismatch = 0;
    $mismatch |= $_ for unpack('C*', $difference);
    return $mismatch == 0;
}

sub reject {
    my ($status, $message) = @_;
    die bless { status => $status, message => $message }, 'MoonRiseCGI::HTTPError';
}

sub send_json {
    my ($status, $data) = @_;
    my %phrases = (
        200 => 'OK', 400 => 'Bad Request', 403 => 'Forbidden', 404 => 'Not Found',
        405 => 'Method Not Allowed', 411 => 'Length Required',
        413 => 'Content Too Large', 415 => 'Unsupported Media Type',
        500 => 'Internal Server Error',
    );
    my $body = JSON::PP->new->utf8->canonical->encode($data);
    binmode STDOUT, ':raw';
    print "Status: $status $phrases{$status}\r\n";
    print "Content-Type: application/json; charset=utf-8\r\n";
    print 'Content-Length: ' . length($body) . "\r\n";
    print "Cache-Control: no-store\r\nX-Content-Type-Options: nosniff\r\n";
    print "Cross-Origin-Resource-Policy: same-origin\r\n";
    print "Allow: POST\r\n" if $status == 405;
    print "\r\n$body";
}

1;
