#!/usr/bin/perl

package PlanetRise;
use strict;
use warnings;
use SwissEph qw(:all);
use JSON::PP ();
use POSIX qw(tzset strftime floor isfinite);
use Time::Local qw(timelocal_posix timegm_posix);

my @BODIES = (
    ['Sun', SE_SUN], ['Mercury', SE_MERCURY], ['Venus', SE_VENUS],
    ['Mars', SE_MARS], ['Jupiter', SE_JUPITER], ['Saturn', SE_SATURN],
    ['Uranus', SE_URANUS], ['Neptune', SE_NEPTUNE], ['Pluto', SE_PLUTO],
);
my $MAX_INPUT = 8192;

main() unless caller;

sub main {
    my $cgi = exists $ENV{GATEWAY_INTERFACE};
    my ($response, $error);
    my $ok = eval {
        local $SIG{ALRM} = sub { die "Calculation timed out.\n" };
        alarm 15;
        $response = calculate(read_request($cgi));
        alarm 0;
        1;
    };
    $error = $@ unless $ok;
    alarm 0;
    swe_close();

    my $status = 200;
    if (!$ok) {
        if (ref($error) eq 'HASH') {
            $status = $error->{status};
            $response = { error => $error->{message} };
        } else {
            warn "PlanetRise: $error";
            $status = 500;
            $response = { error => 'Unable to calculate planet rise times.' };
        }
    }
    binmode STDOUT, ':raw';
    if ($cgi) {
        my %labels = (200 => 'OK', 400 => 'Bad Request', 405 => 'Method Not Allowed',
            411 => 'Length Required', 413 => 'Content Too Large',
            415 => 'Unsupported Media Type', 500 => 'Internal Server Error');
        print "Status: $status $labels{$status}\r\n";
        print "Allow: POST\r\n" if $status == 405;
        print "Content-Type: application/json; charset=UTF-8\r\nCache-Control: no-store\r\n\r\n";
    }
    print JSON::PP->new->utf8->canonical->encode($response), "\n";
    exit($status == 200 ? 0 : 1);
}

sub reject {
    my ($status, $message) = @_;
    die { status => $status, message => $message };
}

sub read_request {
    my ($cgi) = @_;
    reject(400, 'Supply one JSON object on standard input; command-line arguments are not supported.') if @ARGV;
    my $length;
    if ($cgi) {
        reject(405, 'Use POST with a JSON body.') unless ($ENV{REQUEST_METHOD} // '') eq 'POST';
        reject(415, 'Content-Type must be application/json.')
            unless ($ENV{CONTENT_TYPE} // '') =~ /\Aapplication\/json(?:\s*;\s*charset\s*=\s*(?:utf-8|"utf-8"))?\s*\z/i;
        reject(411, 'Content-Length is required.') unless exists $ENV{CONTENT_LENGTH};
        reject(400, 'Invalid Content-Length.') unless $ENV{CONTENT_LENGTH} =~ /\A[0-9]{1,10}\z/;
        $length = 0 + $ENV{CONTENT_LENGTH};
        reject(413, 'JSON input exceeds 8192 bytes.') if $length > $MAX_INPUT;
    }
    binmode STDIN, ':raw' or die "Cannot read standard input: $!\n";
    my $body = '';
    my $limit = $cgi ? $length : $MAX_INPUT + 1;
    while (length($body) < $limit) {
        my $count = read(STDIN, my $chunk, $limit - length($body));
        die "Cannot read standard input: $!\n" unless defined $count;
        last if $count == 0;
        $body .= $chunk;
    }
    reject(400, 'Incomplete JSON body.') if $cgi && length($body) != $length;
    reject(413, 'JSON input exceeds 8192 bytes.') if length($body) > $MAX_INPUT;
    my $data = eval { JSON::PP->new->utf8->max_depth(4)->decode($body) };
    reject(400, 'Invalid JSON input.') if $@;
    reject(400, 'Input must be a JSON object.') unless ref($data) eq 'HASH';
    return $data;
}

sub number {
    my ($data, $field, $min, $max, $default) = @_;
    return $default if !exists($data->{$field}) && defined($default);
    my $value = $data->{$field};
    reject(400, "$field must be a number between $min and $max.")
        unless defined($value) && !ref($value)
        && "$value" =~ /\A[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?\z/
        && isfinite(0 + $value) && $value >= $min && $value <= $max;
    return 0 + $value;
}

sub set_timezone {
    my ($zone) = @_;
    reject(400, 'timezone must be a valid IANA timezone, for example America/Phoenix.')
        unless defined($zone) && !ref($zone) && length($zone) <= 100
        && $zone =~ /\A[A-Za-z][A-Za-z0-9_+-]*(?:\/[A-Za-z0-9_+-]+)*\z/
        && -f "/usr/share/zoneinfo/$zone";
    # Use the operating system's timezone database, as MoonRise does.
    delete $ENV{TZDIR};
    $ENV{TZ} = $zone;
    tzset();
}

sub local_date {
    return strftime('%Y-%m-%d', localtime($_[0]));
}

sub local_day_window {
    my ($date) = @_;
    reject(400, 'date must be a valid Gregorian date in YYYY-MM-DD format.')
        unless defined($date) && !ref($date) && $date =~ /\A([0-9]{4})-([0-9]{2})-([0-9]{2})\z/;
    my ($year, $month, $day) = (0 + $1, 0 + $2, 0 + $3);
    my $nominal = eval { timegm_posix(0, 0, 0, $day, $month - 1, $year - 1900) };
    reject(400, 'date must be a valid Gregorian date in YYYY-MM-DD format.')
        if $@ || $year < 1 || strftime('%Y-%m-%d', gmtime($nominal)) ne $date;
    my $seed = eval { timelocal_posix(0, 0, 0, $day, $month - 1, $year - 1900) };
    reject(400, 'This local date does not exist in the specified timezone.')
        if $@ || local_date($seed) ne $date;

    # Find actual calendar boundaries instead of adding 86400 seconds.
    # Searching around midnight also handles a midnight DST gap or fold.
    my $before = $seed - 3600;
    $before -= 3600 while local_date($before) eq $date;
    my $after = $seed + 3600;
    $after += 3600 while local_date($after) eq $date;
    my ($low, $high) = ($before, $seed);
    while ($high - $low > 1) {
        my $mid = floor(($low + $high) / 2);
        if (local_date($mid) eq $date) { $high = $mid } else { $low = $mid }
    }
    my $start = $high;
    ($low, $high) = ($seed, $after);
    while ($high - $low > 1) {
        my $mid = floor(($low + $high) / 2);
        if (local_date($mid) eq $date) { $low = $mid } else { $high = $mid }
    }
    return ($start, $high);
}

sub epoch_to_ut1 {
    my @utc = gmtime($_[0]);
    my $raw = swe_utc_to_jd($utc[5] + 1900, $utc[4] + 1, $utc[3],
        $utc[2], $utc[1], $utc[0], SE_GREG_CAL);
    die "SwissEph UTC conversion failed.\n"
        unless ref($raw) eq 'HASH' && defined($raw->{retval}) && $raw->{retval} == 0
        && defined($raw->{tjd_ut}) && isfinite($raw->{tjd_ut});
    return $raw->{tjd_ut};
}

sub ut1_to_epoch {
    my $utc = swe_jdut1_to_utc($_[0], SE_GREG_CAL);
    die "SwissEph returned invalid UTC data.\n" unless ref($utc) eq 'HASH'
        && !grep { !defined($utc->{$_}) || !isfinite($utc->{$_}) } qw(iyar imon iday ihou imin dsec);
    # Keep fractional seconds until after checking the local-day bounds.
    return timegm_posix(0, $utc->{imin}, $utc->{ihou}, $utc->{iday},
        $utc->{imon} - 1, $utc->{iyar} - 1900) + $utc->{dsec};
}

sub rise_times {
    my ($body, $start, $end, $start_jd, $end_jd, $location) = @_;
    my @times;
    my $search = $start_jd;
    # A 25-hour day can contain two rises. Continue until outside the day.
    for (1 .. 8) {
        my $raw = swe_rise_trans($search, $body, '', SEFLG_SWIEPH, SE_CALC_RISE,
            [$location->{longitude}, $location->{latitude}, $location->{elevation}], 0, 15);
        die "Unexpected SwissEph rise response.\n"
            unless ref($raw) eq 'HASH' && defined($raw->{retval});
        return \@times if $raw->{retval} == -2; # No rising event: circumpolar.
        die "SwissEph rise calculation failed: " . ($raw->{serr} // 'unknown error') . "\n"
            unless $raw->{retval} == 0;
        my $jd = $raw->{dret}; # The installed Perl binding calls the result dret.
        die "SwissEph returned an invalid rise time.\n"
            unless defined($jd) && !ref($jd) && isfinite($jd) && $jd >= $search;
        return \@times if $jd >= $end_jd;
        my $epoch = ut1_to_epoch($jd);
        if ($epoch >= $start && $epoch < $end) {
            my $rounded = floor($epoch + 0.5);
            $rounded = $end - 1 if $rounded >= $end;
            my $time = strftime('%Y-%m-%dT%H:%M:%S%z', localtime($rounded));
            $time =~ s/([+-][0-9]{2})([0-9]{2})\z/$1:$2/;
            push @times, $time;
        }
        $search = $jd + 1 / 86400; # Avoid rediscovering the same event.
    }
    die "SwissEph returned too many rising events.\n";
}

sub calculate {
    my ($data) = @_;
    my %allowed = map { $_ => 1 } qw(latitude longitude timezone date elevation);
    reject(400, 'Allowed input fields: latitude, longitude, timezone, date, elevation.')
        if grep { !$allowed{$_} } keys %$data;
    my %location = (
        latitude => number($data, 'latitude', -90, 90),
        longitude => number($data, 'longitude', -180, 180),
        elevation => number($data, 'elevation', -500, 10000, 0),
    );
    set_timezone($data->{timezone});
    my $date = exists($data->{date}) ? $data->{date} : local_date(time);
    my ($start, $end) = local_day_window($date);
    my $path = $ENV{SE_EPHE_PATH};
    reject(500, 'Set SE_EPHE_PATH to an existing absolute ephemeris data directory.')
        unless defined($path) && $path =~ m{\A/} && -d $path;
    swe_set_ephe_path($path);
    swe_set_topo($location{longitude}, $location{latitude}, $location{elevation});
    my $start_jd = epoch_to_ut1($start);
    my $end_jd = epoch_to_ut1($end);
    my @planets;
    for my $body (@BODIES) {
        my ($name, $id) = @$body;
        # Do not silently fall back to Moshier if planetary files are missing.
        my $position = swe_calc_ut($start_jd, $id, SEFLG_SWIEPH);
        die "Swiss ephemeris data unavailable for $name: " . ($position->{serr} // 'missing planetary files') . "\n"
            unless ref($position) eq 'HASH' && defined($position->{retval})
            && $position->{retval} >= 0 && ($position->{retval} & SEFLG_SWIEPH);
        my $rises = rise_times($id, $start, $end, $start_jd, $end_jd, \%location);
        push @planets, { name => $name, rise => @$rises ? $rises->[0] : undef, rises => $rises };
    }
    return { date => $date, timezone => $data->{timezone}, %location, planets => \@planets };
}

1;
