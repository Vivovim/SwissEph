#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw($Bin);

# Usage: perl parse_cities.pl [path/to/cities15000.txt]
die "Usage: perl $0 [path/to/cities15000.txt]\n" if @ARGV > 1;
my $filename = @ARGV ? $ARGV[0] : "$Bin/cities15000.txt";

open my $input, '<:encoding(UTF-8)', $filename
    or die "Cannot open '$filename': $!\n";
binmode STDOUT, ':encoding(UTF-8)'
    or die "Cannot set UTF-8 output: $!\n";

print join("\t", qw(city latitude longitude Timezone)), "\n";

my $line_number = 0;
while (my $line = <$input>) {
    ++$line_number;
    $line =~ s/\r?\n\z//;

    # Preserve empty fields so column positions never shift.
    my @fields = split /\t/, $line, -1;
    die "Expected 19 fields in '$filename' at line $line_number; got "
        . scalar(@fields) . "\n" unless @fields == 19;

    # GeoNames columns: name=2, latitude=5, longitude=6, timezone=18.
    # Keep the original city name and timezone identifier, not a UTC offset.
    my ($city, $latitude, $longitude, $timezone) = @fields[1, 4, 5, 17];
    print join("\t", $city, $latitude, $longitude, $timezone), "\n";
}

close $input or die "Cannot close '$filename': $!\n";
