#!/usr/bin/perl

use strict;
use warnings;
use feature qw(say);

use Config;
use FindBin qw($Bin);
use Getopt::Long qw(GetOptions);
use Time::Piece;
use lib "$Bin/local/lib/perl5", "$Bin/local/lib/perl5/$Config{archname}";

use SwissEph qw(:all);

# MySQL defaults match the scripts under done; configure the password before use.
my $dsn = 'DBI:mysql:host=localhost;database=__DB__';
my $db_user = $ENV{PLANETS_DB_USER} // '__USERNAME__';
my $db_password = $ENV{PLANETS_DB_PASSWORD} // '__PASSWORD__';

use constant COARSE_STEP_SECONDS => 12 * 60 * 60;
use constant FINE_STEP_SECONDS   => 5 * 60;
use constant MAX_SEARCH_SECONDS  => 10 * 365 * 24 * 60 * 60;

my $HAS_SWIEPH = eval { my $flag = SEFLG_SWIEPH; defined $flag } ? 1 : 0;

my @PLANETS = (
    # Mercury is intentionally excluded.
    [ SE_VENUS(),   'Venus'   ],
    [ SE_MARS(),    'Mars'    ],
    [ SE_JUPITER(), 'Jupiter' ],
    [ SE_SATURN(),  'Saturn'  ],
    [ SE_URANUS(),  'Uranus'  ],
    [ SE_NEPTUNE(), 'Neptune' ],
    [ SE_PLUTO(),   'Pluto'   ],
);

my %opt = (
    ephe_path => $ENV{SE_EPHE_PATH},
    start_ts  => time,
    dry_run   => 0,
);

GetOptions(
    'help'        => \$opt{help},
    'dry-run'     => \$opt{dry_run},
    'ephe-path=s' => \$opt{ephe_path},
    'start-ts=i'  => \$opt{start_ts},
) or die usage();

if ($opt{help}) { print usage(); exit 0; }
die usage() if @ARGV;
die "Configure PLANETS_DB_PASSWORD or edit the password near the top of the script.\n"
    if !$opt{dry_run} && $db_password eq '__PASSWORD__';

if (defined $opt{ephe_path} && length $opt{ephe_path}) {
    swe_set_ephe_path($opt{ephe_path});
}

my $iflag = base_iflag(\%opt) | SEFLG_SPEED;
my $utc_now = gmtime($opt{start_ts});

# Calculate every row before opening a database connection.
my @rows;

for my $planet (@PLANETS) {
    my ($planet_id, $planet_name) = @$planet;
    my ($retrograde_begin_ts, $retrograde_end_ts) = next_retrograde_window(
        $planet_id,
        $planet_name,
        $iflag,
        $opt{start_ts},
    );

    push @rows, [ $planet_name, $retrograde_begin_ts, $retrograde_end_ts ];
}

swe_close();

if ($opt{dry_run}) {
    # SQL-only output can be redirected to a file and imported on the server.
    say '-- Selected start (UTC): ' . $utc_now->strftime('%Y-%m-%d %H:%M:%S');
    say '-- Dry run: no database connection or insert performed.';
    say 'START TRANSACTION;';
    for my $row (@rows) {
        my ($planet_name, $retrograde_begin_ts, $direct_begin_ts) = @$row;
        # Names come exclusively from the fixed @PLANETS list above.
        say "INSERT INTO `masterbox`.`Planets_Retrogrades` "
            . "(`Planet`, `Retrograde_Begin`, `Direct_Begin`) "
            . "VALUES ('$planet_name', $retrograde_begin_ts, $direct_begin_ts);";
    }
    say 'COMMIT;';
}
else {
    require DBI;
    my $dbh = DBI->connect($dsn, $db_user, $db_password, {
        RaiseError => 1, PrintError => 0, AutoCommit => 0,
    }) or die "Cannot connect to MySQL.\n";

    my $ok = eval {
        my $sth = $dbh->prepare(q{
            INSERT INTO `masterbox`.`Planets_Retrogrades`
                (`Planet`, `Retrograde_Begin`, `Direct_Begin`)
            VALUES (?, ?, ?)
        });
        for my $row (@rows) {
            $sth->execute(@$row);
        }
        $sth->finish();
        $dbh->commit();
        1;
    };
    if (!$ok) {
        my $error = $@ || "Unable to insert planet retrogrades.\n";
        eval { $dbh->rollback(); };
        eval { $dbh->disconnect(); };
        die $error;
    }
    $dbh->disconnect();
    say 'Inserted ' . scalar(@rows) . ' rows into masterbox.Planets_Retrogrades.';
}

sub next_retrograde_window {
    my ($planet_id, $planet_name, $iflag, $start_ts) = @_;

    my ($begin_window_start, $begin_window_end) = find_transition_window(
        $planet_id,
        $planet_name,
        $iflag,
        $start_ts,
        'Retrograde',
    );

    my $retrograde_begin_ts = refine_transition(
        $planet_id,
        $planet_name,
        $iflag,
        $begin_window_start,
        $begin_window_end,
        'Retrograde',
    );

    my ($end_window_start, $end_window_end) = find_transition_window(
        $planet_id,
        $planet_name,
        $iflag,
        $retrograde_begin_ts,
        'Direct',
    );

    my $retrograde_end_ts = refine_transition(
        $planet_id,
        $planet_name,
        $iflag,
        $end_window_start,
        $end_window_end,
        'Direct',
    );

    return ($retrograde_begin_ts, $retrograde_end_ts);
}

sub find_transition_window {
    my ($planet_id, $planet_name, $iflag, $start_ts, $target_status) = @_;

    my $max_ts = $start_ts + MAX_SEARCH_SECONDS;
    my $prev_ts = $start_ts;
    my $prev_status = planet_status_at_ts($planet_id, $planet_name, $iflag, $prev_ts);

    for (my $ts = $start_ts + COARSE_STEP_SECONDS; $ts <= $max_ts; $ts += COARSE_STEP_SECONDS) {
        my $status = planet_status_at_ts($planet_id, $planet_name, $iflag, $ts);

        # Capture the first coarse window where the planet changes into the target status.
        if ($prev_status ne $target_status && $status eq $target_status) {
            return ($prev_ts, $ts);
        }

        $prev_ts = $ts;
        $prev_status = $status;
    }

    die "No $target_status transition found for $planet_name within the search window.\n";
}

sub refine_transition {
    my ($planet_id, $planet_name, $iflag, $window_start, $window_end, $target_status) = @_;

    for (my $ts = $window_start + FINE_STEP_SECONDS; $ts <= $window_end; $ts += FINE_STEP_SECONDS) {
        my $status = planet_status_at_ts($planet_id, $planet_name, $iflag, $ts);
        return $ts if $status eq $target_status;
    }

    my $end_status = planet_status_at_ts($planet_id, $planet_name, $iflag, $window_end);
    return $window_end if $end_status eq $target_status;

    die "Unable to refine the $target_status transition for $planet_name.\n";
}

sub planet_status_at_ts {
    my ($planet_id, $planet_name, $iflag, $ts) = @_;

    my $utc_time = gmtime($ts);
    my $jd = utc_to_jd($utc_time);
    my $calc = swe_calc_ut($jd, $planet_id, $iflag);

    die "SwissEph planet calc failed for $planet_name: $calc->{serr}\n"
        if defined $calc->{serr} && length $calc->{serr};

    my $longitude_speed = $calc->{xx}->[3];
    return $longitude_speed < 0 ? 'Retrograde' : 'Direct';
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

sub base_iflag {
    my ($opt) = @_;
    return SEFLG_SWIEPH if $HAS_SWIEPH && defined $opt->{ephe_path} && length $opt->{ephe_path};
    return SEFLG_MOSEPH;
}

sub usage {
    return <<'USAGE';
Usage:
  /usr/bin/perl Retrogrades-Planets-Full.pl [--ephe-path PATH] [--start-ts UNIX_TIMESTAMP] [--dry-run]

Examples:
  /usr/bin/perl Retrogrades-Planets-Full.pl
  /usr/bin/perl Retrogrades-Planets-Full.pl --dry-run --start-ts 1785283200

Append one row per planet to masterbox.Planets_Retrogrades using the fields
Planet, Retrograde_Begin, and Direct_Begin, in this order:
Venus, Mars, Jupiter, Saturn, Uranus, Neptune, Pluto. Mercury is excluded.

Each row contains the next retrograde beginning after --start-ts (default: now)
and its following direct beginning, as integer UTC Unix timestamps. An already
active retrograde period is skipped. Station times retain the five-minute
search resolution. Existing table rows are retained; repeated runs append rows.

--dry-run prints importable SQL without loading DBI or connecting to MySQL.
Set PLANETS_DB_USER and PLANETS_DB_PASSWORD, or edit the defaults at the top.
Database insertion requires DBI and DBD::mysql for the same Perl interpreter.
The ephemeris path is read from SE_EPHE_PATH; --ephe-path overrides it.
USAGE
}
