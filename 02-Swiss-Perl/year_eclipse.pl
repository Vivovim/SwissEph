#!/usr/bin/perl

use strict;
use warnings;



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





# MySQL connection: edit these values on your server.
# You may set ECLIPSE_DB_PASSWORD instead of storing a password in this file.
my %MYSQL = (
    host     => 'localhost',
    port     => 3306,
    database => '__DB__',
    username => '__USERNAME__',
    password => $ENV{ECLIPSE_DB_PASSWORD} // '__PASSWORD__',
);

use Getopt::Long qw(GetOptions);
use POSIX qw(floor strftime);
use Time::Local qw(timegm_modern);
use SwissEph qw(:all);

main() unless caller;

sub main {
    my %opt = (
        year      => (gmtime(time))[5] + 1900,
        ephe_path => $ENV{SE_EPHE_PATH},
    );
    Getopt::Long::Configure(qw(no_auto_abbrev no_ignore_case));
    GetOptions(
        'year=i'      => \$opt{year},
        'ephe-path=s' => \$opt{ephe_path},
        'dry-run'     => \$opt{dry_run},
        'help|h'      => \$opt{help},
    ) or die usage();
    if ($opt{help}) { print usage(); return; }
    die "Unexpected arguments: @ARGV\n" if @ARGV;
    die "--year must be between 1900 and 2399\n"
        unless $opt{year} >= 1900 && $opt{year} <= 2399;
    die "Set SE_EPHE_PATH or pass --ephe-path with your Swiss Ephemeris data directory.\n"
        unless defined $opt{ephe_path} && length $opt{ephe_path};

    swe_set_ephe_path($opt{ephe_path});
    my $start_jd = epoch_to_jd(timegm_modern(0, 0, 0, 1, 0, $opt{year}));
    my $end_jd = epoch_to_jd(timegm_modern(0, 0, 0, 1, 0, $opt{year} + 1));
    check_ephemeris($start_jd);
    check_ephemeris($end_jd);

    # Calculate everything before connecting to MySQL or writing any rows.
    my @events = (
        find_eclipses('Solar', $start_jd, $end_jd),
        find_eclipses('Lunar', $start_jd, $end_jd),
    );
    @events = sort { $a->{jd} <=> $b->{jd} } @events;
    swe_close();

    print "Worldwide eclipses for $opt{year} (UTC calendar year).\n";
    print "Times are eclipse maxima, rounded to the nearest second.\n\n";
    printf "%-7s %-10s %-15s %s\n", 'Event', 'Type', 'UTC Timestamp', 'UTC';
    for my $event (@events) {
        printf "%-7s %-10s %-15d %s\n", $event->{kind}, $event->{type},
            $event->{epoch}, strftime('%Y-%m-%d %H:%M:%S UTC', gmtime($event->{epoch}));
    }

    if ($opt{dry_run}) {
        print "\nDry run: no database connection or changes.\n";
        return;
    }
    insert_eclipses(\@events);
    printf "\nSaved %d eclipses to Eclipse.\n", scalar @events;
}

sub insert_eclipses {
    my ($events) = @_;
    die "Configure the MySQL password at the top of year_eclipse.pl or set ECLIPSE_DB_PASSWORD.\n"
        if $MYSQL{password} eq '__PASSWORD__';

    require DBI;
    my $dbh = DBI->connect(
        "DBI:mysql:database=$MYSQL{database};host=$MYSQL{host};port=$MYSQL{port}",
        $MYSQL{username}, $MYSQL{password}, {
            RaiseError => 1, PrintError => 0, AutoCommit => 1,
            mysql_enable_utf8mb4 => 1, mysql_connect_timeout => 10,
        },
    ) or die "Cannot connect to MySQL.\n";

    my $ok = eval {
        # Signed BIGINT supports dates before 1970 and after 2038.
        # DDL runs before the transaction because MySQL DDL commits implicitly.
        $dbh->do(q{
            CREATE TABLE IF NOT EXISTS `Eclipse` (
                `event` VARCHAR(10) NOT NULL,
                `type` VARCHAR(10) NOT NULL,
                `utc_timestamp` BIGINT NOT NULL COMMENT 'Eclipse maximum in UTC Unix seconds',
                PRIMARY KEY (`event`, `utc_timestamp`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        });
        $dbh->begin_work();
        my $sth = $dbh->prepare(
            'INSERT INTO `Eclipse` (`event`, `type`, `utc_timestamp`) VALUES (?, ?, ?) '
            . 'ON DUPLICATE KEY UPDATE `type` = ?'
        );
        for my $event (@$events) {
            $sth->execute($event->{kind}, $event->{type}, $event->{epoch}, $event->{type});
        }
        $sth->finish();
        $dbh->commit();
        1;
    };
    my $error = $@;
    if (!$ok) {
        eval { $dbh->rollback() unless $dbh->{AutoCommit}; };
        eval { $dbh->disconnect(); };
        die "Eclipse import failed: $error";
    }
    $dbh->disconnect();
}

sub epoch_to_jd {
    my ($epoch) = @_;
    my @utc = gmtime($epoch);
    my $r = swe_utc_to_jd($utc[5] + 1900, $utc[4] + 1, $utc[3],
        $utc[2], $utc[1], $utc[0], SE_GREG_CAL);
    die "SwissEph UTC conversion failed: " . ($r->{serr} || 'unknown error') . "\n"
        if ($r->{retval} // -1) < 0 || !defined $r->{tjd_ut};
    return $r->{tjd_ut};
}

sub jd_to_epoch {
    my ($jd) = @_;
    # Eclipse results use UT1. Convert to UTC before forming Unix seconds.
    # The installed Perl binding names its hour field 'ihou'. Rounding after
    # adding fractional seconds also handles minute/day rollover correctly.
    my $utc = swe_jdut1_to_utc($jd, SE_GREG_CAL);
    return floor(timegm_modern(0, $utc->{imin}, $utc->{ihou}, $utc->{iday},
        $utc->{imon} - 1, $utc->{iyar}) + $utc->{dsec} + 0.5);
}

sub check_ephemeris {
    my ($jd) = @_;
    for my $body (SE_SUN, SE_MOON) {
        my $r = swe_calc_ut($jd, $body, SEFLG_SWIEPH);
        die "SwissEph calculation failed: " . ($r->{serr} || 'unknown error') . "\n"
            if ($r->{retval} // -1) < 0;
        die "Swiss Ephemeris data unavailable; check the ephemeris path and date coverage. "
            . ($r->{serr} || '') . "\n"
            unless $r->{retval} & SEFLG_SWIEPH;
    }
}

sub find_eclipses {
    my ($kind, $start_jd, $end_jd) = @_;
    my @events;
    # Starting a day early avoids skipping an eclipse near January 1.
    my $cursor = $start_jd - 1;
    while ($cursor < $end_jd) {
        # Type 0 includes all types, including penumbral lunar eclipses.
        my $r = $kind eq 'Solar'
            ? swe_sol_eclipse_when_glob($cursor, SEFLG_SWIEPH, 0, 0)
            : swe_lun_eclipse_when($cursor, SEFLG_SWIEPH, 0, 0);
        die "$kind eclipse search failed: " . ($r->{serr} || 'no result') . "\n"
            if ($r->{retval} // -1) <= 0 || !defined $r->{ecl_maximum};
        my $jd = $r->{ecl_maximum};
        die "$kind eclipse search did not advance\n" unless $jd > $cursor;
        last if $jd >= $end_jd;
        if ($jd >= $start_jd) {
            check_ephemeris($jd);
            push @events, {
                kind => $kind, type => eclipse_type($r->{retval}),
                jd => $jd, epoch => jd_to_epoch($jd),
            };
        }
        $cursor = $jd + 1;
    }
    return @events;
}

sub eclipse_type {
    my ($flags) = @_;
    return 'Hybrid'    if $flags & SE_ECL_ANNULAR_TOTAL;
    return 'Total'     if $flags & SE_ECL_TOTAL;
    return 'Annular'   if $flags & SE_ECL_ANNULAR;
    return 'Partial'   if $flags & SE_ECL_PARTIAL;
    return 'Penumbral' if $flags & SE_ECL_PENUMBRAL;
    die "Unrecognized eclipse type flags: $flags\n";
}

sub usage {
    return <<'USAGE';
Usage: /usr/bin/perl year_eclipse.pl [--year YYYY] [--ephe-path PATH] [--dry-run]

Calculate every worldwide solar and lunar eclipse in a UTC calendar year
and insert its maximum into MySQL table Eclipse. Local visibility is not
considered. Event times are signed integer Unix seconds, rounded to the
nearest second, using a UT1-to-UTC conversion.

  --year YYYY       Default: current UTC year. Supported years: 1900-2399,
                    subject to installed ephemeris data coverage.
  --ephe-path PATH  Swiss Ephemeris data directory or path list.
                    Default: SE_EPHE_PATH environment variable.
  --dry-run         Print events without loading DBI or connecting to MySQL.
  --help            Show this help.

Configure %MYSQL at the top of this file. Set its password there or use
ECLIPSE_DB_PASSWORD. The configured database must already exist; the script
creates Eclipse if necessary with columns event, type, and utc_timestamp.
Rerunning an event updates its type; other stored events are preserved.
All event inserts run in one transaction.

Requires SwissEph, DBI, and DBD::mysql for /usr/bin/perl.

Examples:
  /usr/bin/perl year_eclipse.pl --year 2026 --ephe-path /Users/ctopher/swisseph --dry-run
  /usr/bin/perl year_eclipse.pl --year 2026 --ephe-path /Users/ctopher/swisseph
USAGE
}

1;
