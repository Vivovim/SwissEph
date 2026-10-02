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

# MySQL connection configuration: edit these values before importing.
my %db = (
    host     => 'localhost',
    port     => 3306,
    database => 'your_database',
    user     => 'your_user',
    password => 'your_password',
);

use DBI;
use Encode qw(decode FB_CROAK);
use FindBin qw($Bin);
use Getopt::Long qw(GetOptions);

# Keep Zones.sql beside this script. The default input is Zones.tab beside it.
# Usage: perl import_zones.pl [--dry-run] [path/to/Zones.tab]
# Requires the Perl modules DBI and DBD::mysql.
# Each successful run appends rows; importing the same file again adds duplicates.
my ($dry_run, $help);
GetOptions('dry-run' => \$dry_run, 'help' => \$help) or die usage();
if ($help) {
    print usage();
    exit 0;
}
die usage() if @ARGV > 1;
my $input = @ARGV ? $ARGV[0] : "$Bin/Zones.tab";

# Validate the entire UTF-8, tab-separated file before connecting to MySQL.
# There is no header: every line is city, latitude, longitude, tz.
open my $fh, '<:raw', $input or die "Cannot open $input: $!\n";
my (@rows, $line_number);
while (my $raw = <$fh>) {
    ++$line_number;
    my $line = eval { decode('UTF-8', $raw, FB_CROAK) };
    die "$input line $line_number: invalid UTF-8: $@" if $@;
    $line =~ s/\A\x{FEFF}// if $line_number == 1;
    $line =~ s/\r?\n\z//;

    my @fields = split /\t/, $line, -1;
    die "$input line $line_number: expected exactly four tab-separated fields.\n"
        unless @fields == 4;
    my ($city, $latitude, $longitude, $tz) = @fields;
    die "$input line $line_number: city must contain 1 to 255 characters.\n"
        unless length($city) && length($city) <= 255;
    die "$input line $line_number: tz must contain 1 to 64 characters.\n"
        unless length($tz) && length($tz) <= 64;

    for my $coordinate ([$latitude, 'latitude', 90], [$longitude, 'longitude', 180]) {
        my ($value, $name, $limit) = @$coordinate;
        die "$input line $line_number: invalid $name (expected -$limit to $limit, up to five decimal places).\n"
            unless $value =~ /\A[+-]?\d+(?:\.\d{1,5})?\z/
                && abs($value) <= $limit;
    }

    # Ensure even Latin-1 city names are treated as Unicode by DBD::mysql.
    utf8::upgrade($_) for @fields;
    push @rows, \@fields;
}
close $fh or die "Cannot close $input: $!\n";
die "$input contains no rows.\n" unless @rows;

if ($dry_run) {
    printf "Validated %d rows from %s. No database changes made.\n", scalar @rows, $input;
    exit 0;
}
die "Edit the MySQL connection configuration at the top of this script first.\n"
    if $db{database} eq 'your_database' || $db{user} eq 'your_user'
        || $db{password} eq 'your_password';

# Read the same table definition that can also be run manually with mysql.
open my $schema_fh, '<:raw', "$Bin/Zones.sql"
    or die "Cannot open $Bin/Zones.sql: $!\n";
my $schema = do { local $/; <$schema_fh> };
close $schema_fh or die "Cannot close $Bin/Zones.sql: $!\n";
utf8::upgrade($schema);

my $dsn = "DBI:mysql:database=$db{database};host=$db{host};port=$db{port}";
my $dbh = DBI->connect($dsn, $db{user}, $db{password}, {
    RaiseError           => 1,
    PrintError           => 0,
    AutoCommit           => 1,
    mysql_enable_utf8mb4 => 1,
});

# MySQL CREATE TABLE commits implicitly, so create it before the insert transaction.
my $transaction_started = 0;
my $ok = eval {
    $dbh->do($schema);
    my ($engine) = $dbh->selectrow_array(
        'SELECT ENGINE FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?',
        undef, 'Zones',
    );
    die "Zones must use InnoDB so failed imports can be rolled back.\n"
        unless defined($engine) && lc($engine) eq 'innodb';
    $dbh->do(q{SET SESSION sql_mode = CONCAT_WS(',', NULLIF(@@SESSION.sql_mode, ''), 'STRICT_ALL_TABLES')});
    $dbh->begin_work;
    $transaction_started = 1;
    my $sql = 'INSERT INTO `Zones` (`city`, `latitude`, `longitude`, `tz`) VALUES (?, ?, ?, ?)';
    utf8::upgrade($sql);
    my $insert = $dbh->prepare($sql);
    for my $index (0 .. $#rows) {
        eval { $insert->execute(@{ $rows[$index] }); 1 }
            or die "$input line " . ($index + 1) . ": insert failed: $@";
    }
    $insert->finish;
    $dbh->commit;
    $transaction_started = 0;
    1;
};
unless ($ok) {
    my $error = $@ || "Unknown import error.\n";
    if ($transaction_started) {
        eval { $dbh->rollback; 1 }
            or warn "Rollback failed: $@";
    }
    eval { $dbh->disconnect };
    die "Import failed: $error";
}
$dbh->disconnect;
printf "Inserted %d rows into %s.Zones.\n", scalar @rows, $db{database};

sub usage {
    return "Usage: perl import_zones.pl [--dry-run] [path/to/Zones.tab]\n"
         . "Edit the MySQL configuration at the top before importing.\n"
         . "The database must already exist; the script creates the Zones table.\n"
         . "Each import appends rows, including duplicates on repeated runs.\n";
}
