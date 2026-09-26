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
use Getopt::Long qw(GetOptions);
use POSIX qw(floor strftime tzset);
use Time::Local qw(timelocal_modern timegm_modern);
use SwissEph qw(:all);
use JSON::PP ();

# MySQL configuration: edit these values on the server before enabling cron.
my %MYSQL = (
    host     => 'localhost',
    port     => 3306,
    database => 'CHANGE_ME',
    username => 'CHANGE_ME',
    password => 'CHANGE_ME',
);

# Cron does not normally inherit your interactive shell environment.
# Set an absolute data path here, or set SE_EPHE_PATH in the crontab.
my $EPHE_PATH = $ENV{SE_EPHE_PATH} // '';
my $CALENDAR_TIMEZONE = 'America/Phoenix';
my @PHASE_NAMES = ('New Moon', 'Waxing Crescent', 'First Quarter', 'Waxing Gibbous',
                   'Full Moon', 'Waning Gibbous', 'Last Quarter', 'Waning Crescent');

main() unless caller;

sub main {
    my %opt = (timezone => $CALENDAR_TIMEZONE);
    Getopt::Long::Configure(qw(no_auto_abbrev no_ignore_case));
    GetOptions(
        'month=i'    => \$opt{month},
        'year=i'     => \$opt{year},
        'timezone=s'=> \$opt{timezone},
        'dry-run'   => \$opt{dry_run},
        'debug'     => \$opt{debug},
        'help|h'    => \$opt{help},
    ) or die usage();
    if ($opt{help}) { print usage(); return; }
    die "Unexpected arguments: @ARGV\n" if @ARGV;
    set_timezone($opt{timezone});
    my @now = localtime;
    $opt{month} //= $now[4] + 1;
    $opt{year} //= $now[5] + 1900;
    die "--month must be between 1 and 12\n" if $opt{month} < 1 || $opt{month} > 12;
    die "--year must be between 1000 and 9999\n" if $opt{year} < 1000 || $opt{year} > 9999;

    initialize_ephemeris();
    my ($start, $end) = month_bounds_epoch($opt{year}, $opt{month});
    my @phases = find_phases(epoch_to_jd($start), epoch_to_jd($end), 8);
    for my $phase (@phases) {
        $phase->{epoch} = floor(jd_to_epoch($phase->{jd}) + 0.5);
        printf STDERR "jd_ut=%.10f phase=%s residual=%+.6f arcsec\n",
            $phase->{jd}, $phase->{name},
            signed_phase_error($phase->{jd}, $phase->{target}) * 3600 if $opt{debug};
    }
    swe_close();
    # Finish every calculation before opening the database connection.
    my $row = build_month_row($opt{year}, $opt{month}, $opt{timezone}, \@phases);
    if ($opt{dry_run}) {
        print JSON::PP->new->canonical->pretty->encode($row);
        return;
    }
    insert_month_row($row);
    say "Saved moonphase_new for $row->{month} ($row->{timezone}); "
        . scalar(@phases) . ' phase events.';
}

sub initialize_ephemeris {
    die "Set SE_EPHE_PATH or edit EPHE_PATH at the top of this script.\n"
        unless length $EPHE_PATH;
    swe_set_ephe_path($EPHE_PATH);
}

sub checked_calc {
    my ($jd, $body, $extra_flags) = @_;
    my $result = swe_calc_ut($jd, $body, SEFLG_SWIEPH | ($extra_flags || 0));
    die "SwissEph calculation failed: " . ($result->{serr} || 'unknown error') . "\n"
        if !defined $result->{retval} || $result->{retval} < 0;
    # SwissEph can silently fall back to Moshier if files are missing.
    die "Swiss ephemeris data unavailable; check SE_EPHE_PATH and date coverage. "
        . ($result->{serr} || '') . "\n"
        if $body != SE_ECL_NUT && !($result->{retval} & SEFLG_SWIEPH);
    return $result;
}

sub month_bounds_epoch {
    my ($year, $month) = @_;
    my ($next_year, $next_month) = $month == 12 ? ($year + 1, 1) : ($year, $month + 1);
    return (timelocal_modern(0, 0, 0, 1, $month - 1, $year),
            timelocal_modern(0, 0, 0, 1, $next_month - 1, $next_year));
}

sub epoch_to_jd {
    my ($epoch) = @_;
    my @utc = gmtime($epoch);
    my $result = swe_utc_to_jd($utc[5] + 1900, $utc[4] + 1, $utc[3],
        $utc[2], $utc[1], $utc[0], SE_GREG_CAL);
    die "SwissEph UTC conversion failed: " . ($result->{serr} || 'unknown error') . "\n"
        if !defined $result->{tjd_ut} || ($result->{retval} // -1) < 0;
    return $result->{tjd_ut};
}

sub jd_to_epoch {
    my ($jd) = @_;
    my $utc = swe_jdut1_to_utc($jd, SE_GREG_CAL);
    # Keep fractional seconds until presentation; timegm accepts whole seconds.
    return timegm_modern(0, $utc->{imin}, $utc->{ihou}, $utc->{iday},
        $utc->{imon} - 1, $utc->{iyar}) + $utc->{dsec};
}

sub phase_angle {
    my ($jd) = @_;
    my $sun = checked_calc($jd, SE_SUN);
    my $moon = checked_calc($jd, SE_MOON);
    return normalize_360($moon->{xx}[0] - $sun->{xx}[0]);
}

sub signed_phase_error {
    my ($jd, $target) = @_;
    return normalize_360(phase_angle($jd) - $target + 180) - 180;
}

sub find_phases {
    my ($start_jd, $end_jd, $count) = @_;
    my @names = ('New Moon', 'Waxing Crescent', 'First Quarter', 'Waxing Gibbous',
                 'Full Moon', 'Waning Gibbous', 'Last Quarter', 'Waning Crescent');
    my $spacing = 360 / $count;
    my $lo = $start_jd;
    my $raw = phase_angle($lo);
    my $unwrapped = $raw;
    my $target = $spacing * POSIX::ceil($raw / $spacing);
    my @events;
    # Three-hour brackets unwrap the 360 -> 0 crossing. Search each boundary,
    # including repeated phases in long months, in [month start, next start).
    while ($lo < $end_jd) {
        my $hi = $lo + 0.125;
        $hi = $end_jd if $hi > $end_jd;
        my $next_raw = phase_angle($hi);
        my $next_unwrapped = $unwrapped + normalize_360($next_raw - $raw);
        while ($target <= $next_unwrapped) {
            my $jd = refine_phase_time($lo, $hi, normalize_360($target));
            if ($jd >= $start_jd && $jd < $end_jd) {
                push @events, {name => $names[int($target / 45) % 8],
                    jd => $jd, target => normalize_360($target)};
            }
            $target += $spacing;
        }
        ($lo, $raw, $unwrapped) = ($hi, $next_raw, $next_unwrapped);
    }
    return @events;
}

sub refine_phase_time {
    my ($lo, $hi, $target) = @_;
    return $lo if abs(signed_phase_error($lo, $target)) < 1e-10;
    return $hi if abs(signed_phase_error($hi, $target)) < 1e-10;
    die "Phase root is not bracketed\n"
        if signed_phase_error($lo, $target) > 0 || signed_phase_error($hi, $target) < 0;
    while (($hi - $lo) * 86400 > 0.001) {
        my $mid = ($lo + $hi) / 2;
        if (signed_phase_error($mid, $target) < 0) { $lo = $mid; }
        else { $hi = $mid; }
    }
    return ($lo + $hi) / 2;
}

sub build_month_row {
    my ($year, $month, $timezone, $phases) = @_;
    my %row = (
        month => sprintf('%04d-%02d-01', $year, $month),
        date_updated => strftime('%Y-%m-%d %H:%M:%S', gmtime),
        timezone => $timezone,
        blue_moon_phase => 'na',
        blue_moon_stamp => undef,
    );
    my %slots;
    for my $i (0 .. $#PHASE_NAMES) {
        my $slot = $i + 1;
        $slots{$PHASE_NAMES[$i]} = $slot;
        $row{"phase$slot"} = 'na';
        $row{"stamp$slot"} = undef;
    }
    my (@events, $full_moons);
    $full_moons = 0;
    for my $phase (sort { $a->{jd} <=> $b->{jd} } @$phases) {
        my $slot = $slots{$phase->{name}};
        die "Unknown phase '$phase->{name}'\n" unless defined $slot;
        unless (defined $row{"stamp$slot"}) {
            $row{"phase$slot"} = $phase->{name};
            $row{"stamp$slot"} = $phase->{epoch};
        }
        my $label = $phase->{name};
        if ($label eq 'Full Moon' && ++$full_moons == 2) {
            $label = 'Blue Moon';
            $row{blue_moon_phase} = $label;
            $row{blue_moon_stamp} = $phase->{epoch};
        }
        push @events, { phase => $label, timestamp => $phase->{epoch} };
    }
    # All occurrences, in chronological order, for a complete PHP calendar.
    $row{events_json} = JSON::PP->new->canonical->encode(\@events);
    return \%row;
}

sub month_upsert {
    my ($row) = @_;
    my @columns = ('month', 'date_updated', 'timezone',
        (map { ("phase$_", "stamp$_") } 1 .. 8),
        'blue_moon_phase', 'blue_moon_stamp', 'events_json');
    my @updates = @columns[1 .. $#columns];
    my $sql = 'INSERT INTO `moonphase_new` ('
        . join(', ', map { "`$_`" } @columns) . ') VALUES ('
        . join(', ', ('?') x @columns) . ') ON DUPLICATE KEY UPDATE '
        . join(', ', map { "`$_` = ?" } @updates);
    # Bind update values as well; avoid deprecated MySQL VALUES(column) syntax.
    return ($sql, map { $row->{$_} } (@columns, @updates));
}

sub insert_month_row {
    my ($row, $dbh) = @_;
    my $owns_connection = !defined $dbh;
    if ($owns_connection) {
        for my $key (qw(database username password)) {
            die "Configure MySQL $key at the top of update-phase.pl.\n"
                if $MYSQL{$key} eq 'CHANGE_ME';
        }
        require DBI;
        $dbh = DBI->connect(
            "DBI:mysql:database=$MYSQL{database};host=$MYSQL{host};port=$MYSQL{port}",
            $MYSQL{username}, $MYSQL{password}, {
                RaiseError => 1, PrintError => 0, AutoCommit => 1,
                mysql_enable_utf8mb4 => 1, mysql_connect_timeout => 10,
            });
    }
    my ($sql, @values) = month_upsert($row);
    # One atomic statement inserts one month or refreshes that month's row.
    $dbh->do($sql, undef, @values);
    $dbh->disconnect if $owns_connection;
}

sub normalize_360 {
    my ($angle) = @_;
    return $angle - 360 * floor($angle / 360);
}

sub set_timezone {
    my ($zone) = @_;
    die "Unknown IANA --timezone '$zone'\n"
        unless $zone =~ m{\A[A-Za-z0-9_+/-]+\z} && $zone !~ m{\A/|(?:\A|/)\.\.(?:/|\z)}
            && -f "/usr/share/zoneinfo/$zone";
    $ENV{TZ} = $zone;
    tzset();
}

sub usage {
    return <<'USAGE';
Usage:
  /usr/bin/perl /absolute/path/update-phase.pl
  /usr/bin/perl /absolute/path/update-phase.pl --month 9 --year 2026 --dry-run

Options:
  --month N        Calendar month (1-12); default: current local month.
  --year YYYY      Year (1000-9999); default: current local year.
  --timezone ZONE  IANA time zone; default: America/Phoenix.
  --dry-run        Print the proposed row as JSON; never connect to MySQL.
  --debug          Print phase root diagnostics to stderr.
  --help           Show this help.

Configure MySQL and the ephemeris path at the top of this script, and import
moonphase_new.sql on your server once. Normal execution saves exactly one
monthly row; rerunning the same month updates its row. All eight phase types
are calculated geocentrically. No zodiac or house calculations are performed.

month identifies the local calendar month; date_updated is a UTC DATETIME.
phase1/stamp1 through phase8/stamp8 hold the first occurrence of each phase
(New Moon through Waning Crescent); missing occurrences use 'na' and NULL.
blue_moon_phase/blue_moon_stamp hold the second Full Moon, or 'na' and NULL.
events_json preserves every event in chronological order, including repeats.
All stamps are integer Unix seconds. Month boundaries use the selected zone.
USAGE
}

1;
