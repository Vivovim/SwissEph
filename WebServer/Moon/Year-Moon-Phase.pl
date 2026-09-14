#!/usr/bin/perl

use strict;
use warnings;
use feature qw(say);
use Getopt::Long qw(GetOptions);
use POSIX qw(floor isfinite strftime tzset);
use Time::Local qw(timelocal_modern timegm_modern);
use SwissEph qw(:all);

# Database configuration: edit these values on the machine running MySQL,
# or set the environment variables. Only --insert opens a connection.
my $DB_DSN = $ENV{YEARPHASE_DSN} // 'DBI:mysql:host=localhost;database=__DB__';
my $DB_USER = $ENV{YEARPHASE_DB_USER} // '__USERNAME__';
my $DB_PASSWORD = $ENV{YEARPHASE_DB_PASSWORD} // '__PASSWORD__';
my $CALENDAR_TIMEZONE = 'America/Phoenix';
# Set SE_EPHE_PATH in the environment before running this script.

main() unless caller;

sub main {
    my %opt = (house_system => 'P', phases => 8, elev => 1645, topocentric => 0,
        lat => 34.539400, lon => -112.468300, timezone => $CALENDAR_TIMEZONE);
    Getopt::Long::Configure(qw(no_auto_abbrev no_ignore_case));
    GetOptions(
        'month=i'        => \$opt{month},
        'year=i'         => \$opt{year},
        'house-system=s' => \$opt{house_system},
        'lat=f'          => \$opt{lat},
        'lon=f'          => \$opt{lon},
        'timezone=s'     => \$opt{timezone},
        'phases=i'       => \$opt{phases},
        'all-months'     => \$opt{all_months},
        'topocentric!'   => \$opt{topocentric},
        'elev=f'         => \$opt{elev},
        'debug'          => \$opt{debug},
        'dry-run'        => \$opt{dry_run},
        'insert'         => \$opt{insert},
        'sql'            => \$opt{sql},
        'help|h'         => \$opt{help},
    ) or die usage();
    if ($opt{help}) { print usage(); return; }
    die "Unexpected arguments: @ARGV\n" if @ARGV;
    die "Choose only one of --dry-run, --sql, or --insert\n"
        if grep({ $opt{$_} } qw(dry_run sql insert)) > 1;
    die "Choose --month or --all-months, not both\n"
        if defined $opt{month} && $opt{all_months};
    die "Database output requires all eight phases (--phases 8)\n"
        if ($opt{insert} || $opt{sql}) && $opt{phases} != 8;
    die "Configure YEARPHASE_DB_USER and YEARPHASE_DB_PASSWORD or edit the script.\n"
        if $opt{insert} && ($DB_USER eq '__USERNAME__' || $DB_PASSWORD eq '__PASSWORD__');

    # Check the selected zone against the operating system's IANA database.
    set_timezone($opt{timezone});
    my @now = localtime;
    $opt{year} //= $now[5] + 1900;
    die "--month must be between 1 and 12\n"
        if defined $opt{month} && ($opt{month} < 1 || $opt{month} > 12);
    die "--year must be between 1000 and 9999\n" if $opt{year} < 1000 || $opt{year} > 9999;
    die "--phases must be 4 or 8\n" unless $opt{phases} == 4 || $opt{phases} == 8;
    for my $key (qw(lat lon)) {
        die "--$key is required to calculate houses\n" unless defined $opt{$key};
        die "--$key must be finite\n" unless isfinite($opt{$key});
    }
    die "--lat must be greater than -90 and less than 90\n" if abs($opt{lat}) >= 90;
    die "--lon must be between -180 and 180 (east positive)\n" if abs($opt{lon}) > 180;
    die "--elev must be finite\n" unless isfinite($opt{elev});
    # G has 36 sectors rather than 12 houses. Sunshine requires special state
    # in swe_house_pos; neither is part of this twelve-house report.
    die "Unsupported --house-system; use one of A B C D E F H K L M N O P Q R S T U V W X Y\n"
        unless $opt{house_system} =~ /\A[ABCDEFHKLMNOPQRSTUVWXY]\z/;
    initialize_ephemeris();
    swe_set_topo($opt{lon}, $opt{lat}, $opt{elev}) if $opt{topocentric};
    my @months = defined $opt{month} ? ($opt{month}) : (1 .. 12);
    # Resolve every month before producing SQL or starting a transaction.
    my @calendar = map { calculate_month($opt{year}, $_, \%opt) } @months;
    swe_close();
    if ($opt{sql}) {
        print_sql(\@calendar, \%opt);
    }
    else {
        print_month_report($_, \%opt) for @calendar;
        if ($opt{insert}) {
            insert_calendar(\@calendar);
            say 'Saved ' . scalar(@calendar) . ' month rows to yearphase_new.';
        }
        else {
            say 'Dry run: no database connection or insert performed. Use --sql to export or --insert to save.';
        }
    }
}

sub initialize_ephemeris {
    die "Set SE_EPHE_PATH to your Swiss Ephemeris data directory (or path list).\n"
        unless defined $ENV{SE_EPHE_PATH} && length $ENV{SE_EPHE_PATH};
    swe_set_ephe_path($ENV{SE_EPHE_PATH});
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

sub moon_details {
    my ($jd, $opt) = @_;
    my $moon = checked_calc($jd, SE_MOON, $opt->{topocentric} ? SEFLG_TOPOCTR : 0);
    my $houses = swe_houses_ex($jd, 0, $opt->{lat}, $opt->{lon}, $opt->{house_system});
    die "House system $opt->{house_system} is unavailable at this location/date; choose another system.\n"
        if ($houses->{retval} // -1) < 0;
    my $eps = checked_calc($jd, SE_ECL_NUT)->{xx}[0];
    my $house = swe_house_pos($houses->{armc}, $opt->{lat}, $eps,
        $opt->{house_system}, @{$moon->{xx}}[0, 1]);
    die "SwissEph house assignment failed: " . ($house->{serr} || 'undefined house') . "\n"
        if ($house->{retval} // -1) < 0 || !defined $house->{dhpos}
            || !isfinite($house->{dhpos}) || $house->{dhpos} < 1 || $house->{dhpos} >= 13;
    return {longitude => $moon->{xx}[0], house => int($house->{dhpos})};
}

sub calculate_month {
    my ($year, $month, $opt) = @_;
    my ($start, $end) = month_bounds_epoch($year, $month);
    my @phases = find_phases(epoch_to_jd($start), epoch_to_jd($end), $opt->{phases});
    # Resolve every row first so a calculation failure does not leave a partial month.
    for my $phase (@phases) {
        $phase->{details} = moon_details($phase->{jd}, $opt) unless $opt->{sql};
        $phase->{epoch} = floor(jd_to_epoch($phase->{jd}) + 0.5);
        $phase->{residual} = signed_phase_error($phase->{jd}, $phase->{target}) * 3600
            if $opt->{debug};
    }
    return {date => sprintf('%04d-%02d-01', $year, $month), start => $start,
        end => $end, phases => \@phases};
}

sub print_month_report {
    my ($calendar, $opt) = @_;
    my ($start, $end) = @{$calendar}{qw(start end)};
    say 'Moon Phase Calendar - ' . strftime('%B %Y', localtime($start));
    say 'Local month: ' . strftime('%Y-%m-%d %H:%M:%S %Z %z', localtime($start))
        . ' to ' . strftime('%Y-%m-%d %H:%M:%S %Z %z', localtime($end)) . ' (end excluded)';
    say sprintf('Location: latitude %.6f, longitude %.6f; time zone: %s',
        $opt->{lat}, $opt->{lon}, $opt->{timezone});
    say 'House system: ' . swe_house_name($opt->{house_system}) . " ($opt->{house_system})";
    say 'Phase times: geocentric; zodiac: tropical; Moon placement: '
        . ($opt->{topocentric} ? "topocentric (elevation $opt->{elev} m)" : 'geocentric');
    say 'House = Moon occupancy at the phase instant.';
    say 'Crescent/gibbous entries mark 45, 135, 225 and 315 degree elongations.' if $opt->{phases} == 8;
    say "SE_EPHE_PATH: $ENV{SE_EPHE_PATH}" if $opt->{debug};
    say '';
    my $format = '%-16s  %-30s  %-23s  %-23s  %5s';
    say sprintf($format, 'Phase', 'Local time', 'UTC time', 'Moon Position', 'House');
    say '-' x 109;
    my $full_moons = 0;
    for my $phase (@{$calendar->{phases}}) {
        my $detail = $phase->{details};
        my $label = $phase->{name};
        $label = 'Blue Moon' if $phase->{target} == 180 && ++$full_moons == 2;
        say sprintf($format, $label,
            strftime('%Y-%m-%d %H:%M:%S %Z %z', localtime($phase->{epoch})),
            strftime('%Y-%m-%d %H:%M:%S UTC', gmtime($phase->{epoch})),
            format_longitude($detail->{longitude}), $detail->{house});
        say sprintf('  [debug] jd_ut=%.10f target=%.0f residual=%+.6f arcsec',
            $phase->{jd}, $phase->{target}, $phase->{residual})
            if $opt->{debug};
    }
    if ($opt->{phases} == 8) {
        my $row = month_row($calendar);
        say "Database date: $calendar->{date}; first occurrence of each phase:";
        for my $slot (1 .. 9) {
            say sprintf('  phase%d=%-16s stamp%d=%s', $slot, $row->[2 * $slot - 1],
                $slot, $row->[2 * $slot] // 'NULL');
        }
    }
    say '';
}

# Fixed slots: New, Waxing Crescent, First Quarter, Waxing Gibbous, Full,
# Waning Gibbous, Last Quarter, Waning Crescent. The first event of each
# kind in the selected calendar month is stored. Slot 9 is its second Full
# Moon (monthly Blue Moon). Missing labels are 'na'; missing stamps are NULL.
sub month_row {
    my ($calendar) = @_;
    my @row = ($calendar->{date}, map { ('na', undef) } 1 .. 9);
    my $full_moons = 0;
    for my $phase (@{$calendar->{phases}}) {
        my $slot = int($phase->{target} / 45) + 1;
        my $label = $phase->{name};
        if ($phase->{target} == 180 && ++$full_moons == 2) {
            $slot = 9;
            $label = 'Blue Moon';
        }
        my $index = 2 * $slot - 1;
        next if defined $row[$index + 1];
        @row[$index, $index + 1] = ($label, $phase->{epoch});
    }
    return \@row;
}

sub database_columns {
    return ('date', map { ("phase$_", "stamp$_") } 1 .. 9);
}

sub insert_statement {
    my @columns = database_columns();
    # Bind again for updates; avoids version-dependent VALUES()/alias syntax.
    return 'INSERT INTO `yearphase_new` (' . join(', ', map { "`$_`" } @columns)
        . ') VALUES (' . join(', ', ('?') x @columns) . ')'
        . ' ON DUPLICATE KEY UPDATE '
        . join(', ', map { "`$_` = ?" } @columns[1 .. $#columns]);
}

sub print_sql {
    my ($calendar, $opt) = @_;
    my @columns = database_columns();
    say '-- Import yearphase_new.sql first. Calendar timezone: ' . $opt->{timezone};
    say '-- phase1..8: first occurrence of each named phase; phase9: second Full Moon.';
    say '-- All stamps are UTC Unix seconds. Missing stamps are NULL.';
    say 'START TRANSACTION;';
    for my $month (@$calendar) {
        my $row = month_row($month);
        # Only generated ISO dates, fixed phase labels and integers reach here.
        my @values = map { !defined $_ ? 'NULL' : /\A-?\d+\z/ ? $_ : "'$_'" } @$row;
        say 'INSERT INTO `yearphase_new` (' . join(', ', map { "`$_`" } @columns)
            . ') VALUES (' . join(', ', @values) . ')'
            . ' ON DUPLICATE KEY UPDATE '
            . join(', ', map { "`$columns[$_]` = $values[$_]" } 1 .. $#columns) . ';';
    }
    say 'COMMIT;';
}

sub insert_calendar {
    my ($calendar) = @_;
    require DBI;
    my $dbh = DBI->connect($DB_DSN, $DB_USER, $DB_PASSWORD, {
        RaiseError => 1, PrintError => 0, AutoCommit => 1,
    }) or die "Cannot connect to MySQL.\n";
    my $ok = eval {
        $dbh->begin_work();
        my $sth = $dbh->prepare(insert_statement());
        for my $month (@$calendar) {
            my $row = month_row($month);
            $sth->execute(@$row, @$row[1 .. $#$row]);
        }
        $sth->finish();
        $dbh->commit();
        1;
    };
    my $error = $@;
    if (!$ok) {
        eval { $dbh->rollback(); };
        eval { $dbh->disconnect(); };
        die "Calendar insert failed; transaction rolled back: $error";
    }
    $dbh->disconnect();
}

sub normalize_360 {
    my ($angle) = @_;
    return $angle - 360 * floor($angle / 360);
}

sub format_longitude {
    my ($longitude) = @_;
    my @signs = qw(Aries Taurus Gemini Cancer Leo Virgo Libra Scorpio Sagittarius Capricorn Aquarius Pisces);
    my $seconds = floor(normalize_360($longitude) * 3600 + 0.5) % (360 * 3600);
    my $sign = int($seconds / (30 * 3600));
    my $within = $seconds % (30 * 3600);
    return sprintf('%02d %s %02dm %02ds', int($within / 3600), $signs[$sign],
        int($within / 60) % 60, $within % 60);
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
  export SE_EPHE_PATH=/Users/ctopher/swisseph
  /usr/bin/perl Year-Moon-Phase.pl --year 2026 --dry-run
  /usr/bin/perl Year-Moon-Phase.pl --year 2026 --sql > yearphase-2026.sql
  /usr/bin/perl Year-Moon-Phase.pl --year 2026 --insert

Database options:
  --dry-run          Print calendar and stored values; no DB access (default).
  --sql              Print importable month INSERT/UPDATE statements only;
                     no DBI, MySQL driver, or connection required.
  --insert           Save to MySQL using the configuration near the top.
                     Requires DBI and DBD::mysql on the destination machine.
                     Import yearphase_new.sql there before first use.
                     All months are saved in one transaction. Reruns update
                     existing month rows using the unique date key.

Options:
  --month N           Only this month (1-12); default: all 12 months.
  --year YYYY         Year (1000-9999); default: current local year.
  --lat DEGREES       Observer latitude, north positive; default 34.539400.
  --lon DEGREES       Observer longitude, east positive; default -112.468300.
  --timezone ZONE     IANA time zone; default America/Phoenix.
  --house-system P    SwissEph uppercase code; default P (Placidus).
                     Common alternatives: K Koch, W Whole Sign, E Equal,
                     R Regiomontanus, C Campanus, O Porphyry.
                     G (36 sectors) and I/i (Sunshine) are unsupported.
  --phases 4|8        Default 8: all 45-degree phase milestones.
                     4 selects New, First Quarter, Full, Last Quarter.
  --all-months        Explicitly select January through December (default).
  --topocentric      Observer-relative Moon sign/house (times stay geocentric).
  --no-topocentric   Geocentric Moon sign/house (default).
  --elev METERS      Observer elevation for --topocentric; default 1645.
  --debug            Print ephemeris path and phase root diagnostics.
  --help             Show this help.

Set SE_EPHE_PATH in your environment before running. There is no built-in
path and no silent Moshier fallback. Each month covers local day 1 at 00:00
through (excluding) the next month's day 1, with all events in time order.
Moon Position is tropical zodiac longitude; House is the numbered house
occupied at the phase, not a separate sign/house ingress event.

Table yearphase_new has one row per month; date is YYYY-MM-01 in --timezone.
phase1..8 store the FIRST occurrence in that month of New Moon, Waxing
Crescent, First Quarter, Waxing Gibbous, Full Moon, Waning Gibbous,
Last Quarter, and Waning Crescent, respectively. Other repeats remain in
the printed calendar but are not stored. phase9 is Blue Moon for the SECOND
Full Moon in that calendar month (not the seasonal Blue Moon definition).
Missing phase labels are 'na'; missing stamps are SQL NULL, including stamp9.
stamp1..9 are signed BIGINT UTC Unix seconds, rounded to the nearest second.
Do not mix calendar timezones in one table: reruns replace the same date row.
Crescent/gibbous stamps are 45-degree milestones, not interval durations.
--phases 4 is a display-only option; database output requires eight phases.
USAGE
}

1;
