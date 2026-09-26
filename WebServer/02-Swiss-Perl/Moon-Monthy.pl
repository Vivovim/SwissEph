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
use File::Basename qw(basename);
use FindBin qw($Bin);
use Getopt::Long qw(GetOptions);
use POSIX qw(floor tzset);
use Time::Local qw(timegm);
use Time::Piece;
use lib "$Bin/local/lib/perl5", "$Bin/local/lib/perl5/$Config{archname}";

use SwissEph qw(:all);

# Configure these here or through the environment. Never put a password on the
# command line. The defaults match the other database scripts in this folder.
my $dsn = $ENV{MOONPHASE_DSN} // 'DBI:mysql:host=localhost;database=__DB__';
my $db_user = $ENV{MOONPHASE_DB_USER} // '__USERNAME__';
my $db_password = $ENV{MOONPHASE_DB_PASSWORD} // '__PASSWORD__';

my $LOCAL_TZ = 'America/Phoenix';
set_timezone($LOCAL_TZ);
my $HAS_SWIEPH = eval { my $flag = SEFLG_SWIEPH; defined $flag } ? 1 : 0;

my $now = gmtime(time);
my %opt = (
    debug        => 0,
    elev         => 0,
    ephe_path    => $ENV{SE_EPHE_PATH},
    house_system => 'P',
    month        => $now->mon,
    dry_run      => 0,
    topocentric  => 1,
    year         => $now->year,
);

GetOptions(
    'help'           => \$opt{help},
    'dry-run'        => \$opt{dry_run},
    'debug!'         => \$opt{debug},
    'lat=f'          => \$opt{lat},
    'lon=f'          => \$opt{lon},
    'elev=f'         => \$opt{elev},
    'ephe-path=s'    => \$opt{ephe_path},
    'house-system=s' => \$opt{house_system},
    'month=i'        => \$opt{month},
    'topocentric!'   => \$opt{topocentric},
    'year=i'         => \$opt{year},
) or die usage();

if ($opt{help}) { print usage(); exit 0; }
die usage() if @ARGV;
die "Supply both --lat and --lon, or omit both.\n"
    if defined($opt{lat}) != defined($opt{lon});
die "--lat must be between -90 and 90; --lon between -180 and 180.\n"
    if defined $opt{lat} && (abs($opt{lat}) > 90 || abs($opt{lon}) > 180);
die "Configure MOONPHASE_DB_PASSWORD or edit the password near the top of the script.\n"
    if !$opt{dry_run} && $db_password eq '__PASSWORD__';

die "--month must be between 1 and 12\n"
    if defined $opt{month} && ($opt{month} < 1 || $opt{month} > 12);

die "--year must be a four-digit year\n"
    if $opt{year} < 1000 || $opt{year} > 9999;

$opt{house_system} = uc substr($opt{house_system}, 0, 1);

if (defined $opt{ephe_path} && length $opt{ephe_path}) {
    swe_set_ephe_path($opt{ephe_path});
}

if ($opt{topocentric} && defined $opt{lat}) {
    swe_set_topo($opt{lon}, $opt{lat}, $opt{elev});
}

my $phase_epochs = print_month_report($opt{year}, $opt{month}, \%opt);
swe_close();

# All five phases are calculated successfully before opening the database.
# A single INSERT writes the complete row atomically to the InnoDB table.
if ($opt{dry_run}) {
    say 'Dry run: no database connection or insert performed.';
}
else {
    require DBI;
    my $dbh = DBI->connect($dsn, $db_user, $db_password, {
        RaiseError => 1, PrintError => 0, AutoCommit => 1,
    }) or die "Cannot connect to MySQL.\n";
    my $sth = $dbh->prepare(q{
        INSERT INTO moonphase
            (`date`, `phase2`, `phase`, `nmoon`, `fq`, `fmoon`, `lq`, `xnmoon`)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    });
    my $inserted_at = time;
    $sth->execute($inserted_at, '0.0', '0.0', @$phase_epochs);
    $sth->finish();
    $dbh->disconnect();
    say "Inserted moonphase row: date=$inserted_at, phase2=0.0, phase=0.0";
}

sub print_month_report {
    my ($year, $month, $opt) = @_;

    my $start_epoch = timegm(0, 0, 0, 1, $month - 1, $year);
    my $start_utc = gmtime($start_epoch);
    my $start_jd = utc_to_jd($start_utc);

    my $new_moon_jd = find_next_phase($start_jd, 0, $opt);
    my ($next_year, $next_month) = $month == 12 ? ($year + 1, 1) : ($year, $month + 1);
    my $end_jd = utc_to_jd(scalar gmtime(timegm(0, 0, 0, 1, $next_month - 1, $next_year)));
    die "No new moon in the selected UTC calendar month; no row inserted.\n"
        if $new_moon_jd >= $end_jd;
    my $first_quarter_jd = find_next_phase($new_moon_jd, 90, $opt);
    my $full_moon_jd = find_next_phase($first_quarter_jd, 180, $opt);
    my $last_quarter_jd = find_next_phase($full_moon_jd, 270, $opt);
    my $next_new_moon_jd = find_next_phase($last_quarter_jd, 0, $opt);

    my @phases = (
        [ 'New Moon',      $new_moon_jd ],
        [ 'First Quarter', $first_quarter_jd ],
        [ 'Full Moon',     $full_moon_jd ],
        [ 'Last Quarter',  $last_quarter_jd ],
        [ 'Next New Moon', $next_new_moon_jd ],
    );
    my $ephe_status = inspect_ephemeris_path($opt->{ephe_path});

    my $month_label = $start_utc->strftime('%B %Y');
    say "=" x 88;
    say "Moon Phase Calendar for $month_label";
    say "Search start (UTC): " . $start_utc->strftime('%Y-%m-%d %H:%M:%S');
    say "Phase timing: geocentric Sun/Moon longitude relationship";
    if (defined $opt->{lat}) {
        say sprintf(
            "Location: lat %.6f, lon %.6f, elev %.1f m",
            $opt->{lat},
            $opt->{lon},
            $opt->{elev},
        );
        say "House system: " . swe_house_name($opt->{house_system}) . " ($opt->{house_system})";
        say "Moon placement: "
            . ($opt->{topocentric} ? 'topocentric position for sign/house' : 'geocentric position for sign/house');
    }
    say "Ephemeris path: " . ((defined $opt->{ephe_path} && length $opt->{ephe_path}) ? $opt->{ephe_path} : '(SwissEph default)');
    say "Requested ephemeris mode: " . ephemeris_mode_label($opt);
    say sprintf(
        "Ephemeris files seen: %d (moon: %s, planet: %s, asteroid: %s)",
        $ephe_status->{file_count},
        yesno($ephe_status->{has_moon_files}),
        yesno($ephe_status->{has_planet_files}),
        yesno($ephe_status->{has_asteroid_files}),
    );
    say "Ephemeris sample files: " . ($ephe_status->{sample_files} || '(none found)');
    print_ephemeris_debug($ephe_status) if $opt->{debug};
    say "";
    say sprintf(
        "%-15s  %-19s  %-19s  %-19s  %-5s",
        'Phase',
        "Local ($LOCAL_TZ)",
        'UTC',
        'Moon Position',
        'House',
    );
    say "-" x 88;

    for my $phase (@phases) {
        my ($label, $jd) = @$phase;
        my $epoch = jd_to_epoch($jd);
        my $detail = defined $opt->{lat} ? moon_details($jd, $opt) : {
            local_time => scalar localtime($epoch),
            utc_time => scalar gmtime($epoch),
            position_label => '-', house => '-',
        };
        say sprintf(
            "%-15s  %-19s  %-19s  %-19s  %5s",
            $label,
            format_time($detail->{local_time}),
            format_time($detail->{utc_time}),
            $detail->{position_label},
            $detail->{house},
        );
        say "  Unix timestamp: $epoch";
        print_phase_debug($label, $jd, phase_debug_metrics($jd, phase_target_degrees($label), $opt))
            if $opt->{debug};
    }

    say "";
    return [ map { jd_to_epoch($_->[1]) } @phases ];
}

sub moon_details {
    my ($jd, $opt) = @_;

    my $iflag = base_iflag($opt);
    $iflag |= SEFLG_TOPOCTR if $opt->{topocentric};

    my $houses = swe_houses_ex(
        $jd,
        $iflag,
        $opt->{lat},
        $opt->{lon},
        $opt->{house_system},
    );
    die "SwissEph houses failed: $houses->{serr}\n"
        if defined $houses->{serr} && length $houses->{serr};

    my $ecl_nut = swe_calc_ut($jd, SE_ECL_NUT, base_iflag($opt));
    die "SwissEph obliquity failed: $ecl_nut->{serr}\n"
        if defined $ecl_nut->{serr} && length $ecl_nut->{serr};

    my $moon = swe_calc_ut($jd, SE_MOON, $iflag);
    die "SwissEph moon calc failed: $moon->{serr}\n"
        if defined $moon->{serr} && length $moon->{serr};

    my ($longitude, $latitude) = @{ $moon->{xx} }[0, 1];
    my $house = swe_house_pos(
        $houses->{armc},
        $opt->{lat},
        $ecl_nut->{xx}->[0],
        $opt->{house_system},
        $longitude,
        $latitude,
    );
    die "SwissEph house assignment failed: $house->{serr}\n"
        if defined $house->{serr} && length $house->{serr};

    my $epoch = jd_to_epoch($jd);
    my $local_time = scalar localtime($epoch);
    my $utc_time = scalar gmtime($epoch);

    return {
        house          => $house->{ihno},
        local_time     => $local_time,
        position_label => format_longitude($longitude),
        utc_time       => $utc_time,
    };
}

sub find_next_phase {
    my ($start_jd, $target_deg, $opt) = @_;

    my $step_days = 0.125;
    my $max_days = 40;
    my $tol_angle = 1e-7;

    my $prev_jd = $start_jd;
    my $prev_raw = phase_angle($prev_jd, $opt);
    my $prev_unwrapped = $prev_raw;
    my $target_abs = $target_deg;

    $target_abs += 360 while $target_abs < ($prev_unwrapped - $tol_angle);

    my $offset = 0;
    my $max_steps = int($max_days / $step_days) + 2;

    for my $step (1 .. $max_steps) {
        my $jd = $start_jd + ($step * $step_days);
        my $raw = phase_angle($jd, $opt);

        if ($raw < $prev_raw - 180) {
            $offset += 360;
        }
        elsif ($raw > $prev_raw + 180) {
            $offset -= 360;
        }

        my $current_unwrapped = $raw + $offset;
        if ($current_unwrapped >= $target_abs) {
            return refine_phase_time($prev_jd, $jd, $target_deg, $opt);
        }

        $prev_jd = $jd;
        $prev_raw = $raw;
        $prev_unwrapped = $current_unwrapped;
    }

    die sprintf("Unable to find %.0f-degree phase after JD %.8f\n", $target_deg, $start_jd);
}

sub phase_target_degrees {
    my ($label) = @_;

    my %targets = (
        'New Moon'      => 0,
        'First Quarter' => 90,
        'Full Moon'     => 180,
        'Last Quarter'  => 270,
        'Next New Moon' => 0,
    );

    return $targets{$label};
}

sub refine_phase_time {
    my ($lo, $hi, $target_deg, $opt) = @_;

    my $flo = signed_phase_error($lo, $target_deg, $opt);
    my $fhi = signed_phase_error($hi, $target_deg, $opt);

    return $lo if abs($flo) < 1e-10;
    return $hi if abs($fhi) < 1e-10;

    my $jd = ($lo + $hi) / 2;

    for (1 .. 20) {
        my ($error, $speed) = phase_error_and_speed($jd, $target_deg, $opt);
        return $jd if abs($error) < 1e-9;

        last if abs($speed) < 1e-9;

        my $next_jd = $jd - ($error / $speed);
        last if $next_jd <= $lo || $next_jd >= $hi;

        $jd = $next_jd;
    }

    for (1 .. 100) {
        my $mid = ($lo + $hi) / 2;
        my $fmid = signed_phase_error($mid, $target_deg, $opt);

        return $mid if abs($fmid) < 1e-10 || ($hi - $lo) * 86400 < 0.25;

        if (($flo < 0 && $fmid < 0) || ($flo > 0 && $fmid > 0)) {
            $lo = $mid;
            $flo = $fmid;
        }
        else {
            $hi = $mid;
            $fhi = $fmid;
        }
    }

    return ($lo + $hi) / 2;
}

sub phase_angle {
    my ($jd, $opt) = @_;

    my $iflag = base_iflag($opt);
    my $sun = swe_calc_ut($jd, SE_SUN, $iflag);
    die "SwissEph sun calc failed: $sun->{serr}\n"
        if defined $sun->{serr} && length $sun->{serr};

    my $moon = swe_calc_ut($jd, SE_MOON, $iflag);
    die "SwissEph moon calc failed: $moon->{serr}\n"
        if defined $moon->{serr} && length $moon->{serr};

    return normalize_360($moon->{xx}->[0] - $sun->{xx}->[0]);
}

sub signed_phase_error {
    my ($jd, $target_deg, $opt) = @_;

    my $error = phase_angle($jd, $opt) - $target_deg;
    $error -= 360 while $error > 180;
    $error += 360 while $error <= -180;

    return $error;
}

sub phase_error_and_speed {
    my ($jd, $target_deg, $opt) = @_;

    my $iflag = base_iflag($opt) | SEFLG_SPEED;
    my $sun = swe_calc_ut($jd, SE_SUN, $iflag);
    die "SwissEph sun calc failed: $sun->{serr}\n"
        if defined $sun->{serr} && length $sun->{serr};

    my $moon = swe_calc_ut($jd, SE_MOON, $iflag);
    die "SwissEph moon calc failed: $moon->{serr}\n"
        if defined $moon->{serr} && length $moon->{serr};

    my $error = normalize_360($moon->{xx}->[0] - $sun->{xx}->[0]) - $target_deg;
    $error -= 360 while $error > 180;
    $error += 360 while $error <= -180;

    my $speed = $moon->{xx}->[3] - $sun->{xx}->[3];
    return ($error, $speed);
}

sub phase_debug_metrics {
    my ($jd, $target_deg, $opt) = @_;

    my ($error_deg, $speed_deg_per_day) = phase_error_and_speed($jd, $target_deg, $opt);
    my $error_arcsec = $error_deg * 3600;
    my $speed_arcsec_per_hour = $speed_deg_per_day * 3600 / 24;
    my $seconds_from_exact = abs($speed_deg_per_day) > 0
        ? abs($error_deg / $speed_deg_per_day) * 86400
        : undef;

    return {
        error_arcsec          => $error_arcsec,
        error_deg             => $error_deg,
        jd                    => $jd,
        seconds_from_exact    => $seconds_from_exact,
        speed_arcsec_per_hour => $speed_arcsec_per_hour,
        speed_deg_per_day     => $speed_deg_per_day,
    };
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

sub jd_to_epoch {
    my ($jd) = @_;

    # swe_calc_ut works in UT1, which is not exactly UTC. Convert through Swiss
    # Ephemeris before rounding to a Unix second (POSIX has no leap-second slot).
    my $utc = swe_jdut1_to_utc($jd, SE_GREG_CAL);
    my $hour = $utc->{ihour} // $utc->{ihou};
    die "SwissEph UT1->UTC conversion failed.\n" unless defined $hour;
    return timegm(0, $utc->{imin}, $hour, $utc->{iday}, $utc->{imon} - 1, $utc->{iyar})
        + int($utc->{dsec} + 0.5);
}

sub base_iflag {
    my ($opt) = @_;
    return SEFLG_SWIEPH if $HAS_SWIEPH && defined $opt->{ephe_path} && length $opt->{ephe_path};
    return SEFLG_MOSEPH;
}

sub ephemeris_mode_label {
    my ($opt) = @_;
    return 'Swiss Ephemeris (SEFLG_SWIEPH)' if base_iflag($opt) != SEFLG_MOSEPH;
    return 'Moshier fallback (SEFLG_MOSEPH)';
}

sub print_ephemeris_debug {
    my ($status) = @_;
    say "Debug:";
    say "  SE_EPHE_PATH value: " . ($status->{path_label});
    say "  Path exists: " . yesno($status->{exists});
    say "  Path readable: " . yesno($status->{readable});
    say "  Total matching ephemeris files: " . $status->{file_count};
    say "  Moon files present: " . yesno($status->{has_moon_files});
    say "  Planet files present: " . yesno($status->{has_planet_files});
    say "  Asteroid files present: " . yesno($status->{has_asteroid_files});
    say "  Sample files: " . ($status->{sample_files} || '(none found)');
    say "  If this shows zero files, SwissEph may silently fall back even if SEFLG_SWIEPH is requested.";
}

sub inspect_ephemeris_path {
    my ($path) = @_;

    my $path_label = (defined $path && length $path) ? $path : '(unset)';
    my $exists = defined $path && length $path && -d $path ? 1 : 0;
    my $readable = $exists && -r $path ? 1 : 0;
    my @files;

    if ($readable) {
        @files = sort grep { -f $_ } glob("$path/*");
    }

    my @named = map { basename($_) } grep { basename($_) =~ /\Ase(?:mo|pl|as)/i } @files;
    my @sample = @named ? @named[0 .. (@named > 5 ? 4 : $#named)] : ();

    my $has_moon_files = scalar grep { /\Asemo/i } @named;
    my $has_planet_files = scalar grep { /\Asepl/i } @named;
    my $has_asteroid_files = scalar grep { /\Aseas/i } @named;

    return {
        exists             => $exists,
        file_count         => scalar @named,
        has_asteroid_files => $has_asteroid_files ? 1 : 0,
        has_moon_files     => $has_moon_files ? 1 : 0,
        has_planet_files   => $has_planet_files ? 1 : 0,
        path_label         => $path_label,
        readable           => $readable,
        sample_files       => @sample ? join(', ', @sample) : '',
    };
}

sub print_phase_debug {
    my ($label, $jd, $metrics) = @_;

    say sprintf(
        "  [debug] %-15s jd_ut=%.9f residual=%+.6f arcsec speed=%.6f deg/day time_error_est=%s",
        $label,
        $jd,
        $metrics->{error_arcsec},
        $metrics->{speed_deg_per_day},
        defined $metrics->{seconds_from_exact}
            ? sprintf('%.4f sec', $metrics->{seconds_from_exact})
            : 'n/a',
    );
}

sub format_time {
    my ($time) = @_;
    $time = scalar localtime($time) unless ref $time;
    return $time->strftime('%Y-%m-%d %H:%M:%S');
}

sub normalize_360 {
    my ($angle) = @_;
    $angle -= 360 * floor($angle / 360);
    $angle += 360 if $angle < 0;
    return $angle;
}

sub format_longitude {
    my ($longitude) = @_;

    my @signs = qw(Aries Taurus Gemini Cancer Leo Virgo Libra Scorpio Sagittarius Capricorn Aquarius Pisces);
    my $normalized = normalize_360($longitude);
    my $sign_index = int($normalized / 30);
    my $degrees_in_sign = $normalized - ($sign_index * 30);
    my $degrees = int($degrees_in_sign);
    my $minutes = int(($degrees_in_sign - $degrees) * 60);
    my $seconds = int((((($degrees_in_sign - $degrees) * 60) - $minutes) * 60) + 0.5);

    if ($seconds == 60) {
        $seconds = 0;
        $minutes++;
    }
    if ($minutes == 60) {
        $minutes = 0;
        $degrees++;
    }
    if ($degrees == 30) {
        $degrees = 0;
        $sign_index = ($sign_index + 1) % 12;
    }

    return sprintf('%2d %s %02dm %02ds', $degrees, $signs[$sign_index], $minutes, $seconds);
}

sub set_timezone {
    my ($tz) = @_;
    $ENV{TZ} = $tz;
    tzset();
}

sub yesno {
    my ($value) = @_;
    return $value ? 'yes' : 'no';
}

sub usage {
    return <<'USAGE';
Usage:
  /usr/bin/perl moon_phase_calendar.pl [options]
  /usr/bin/perl moon_phase_calendar.pl --dry-run [options]

Options:
  --debug              Print ephemeris path checks and exact phase diagnostics.
  --dry-run            Print phase times without connecting to MySQL.
  --month N            Select one month (1-12). Default: current UTC month.
  --year YYYY          Year to report. Default: current UTC year.
  --lat N --lon N      Optional location for Moon sign/house reporting.
  --house-system P     House system letter. Default: P (Placidus).
  --topocentric        Use topocentric Moon position for sign/house output.
  --no-topocentric     Use geocentric Moon position for sign/house output.
  --elev METERS        Elevation above sea level. Default: 0.
  --ephe-path PATH     Swiss Ephemeris data path. Default: $SE_EPHE_PATH.

Notes:
  The search anchor is the first day of the selected month at 00:00 UTC.
  Each report begins with the first New Moon on/after that anchor, then lists
  First Quarter, Full Moon, Last Quarter, and the following New Moon.
  These belong to one lunar cycle; later phases can fall in the following month.
  If there are two new moons in a month, nmoon is the first and xnmoon the second.
  A month without a new moon fails without writing a row.

  Upload performs one INSERT with eight columns. date is the current Unix
  timestamp at insertion; nmoon, fq, fmoon, lq, xnmoon are Unix seconds for each
  phase in UTC. phase2 and phase contain the literal placeholder '0.0'.
  Existing rows are retained; MySQL assigns recid automatically using AUTO_INCREMENT.

  Configure MOONPHASE_DSN, MOONPHASE_DB_USER, MOONPHASE_DB_PASSWORD in the
  environment, or edit the configuration near the top of this script.
  Requires SwissEph, DBI and DBD::mysql installed for the SAME Perl interpreter.
  On this machine SwissEph is available to /usr/bin/perl; use it from bash.
USAGE
}
