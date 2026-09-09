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

my @signs = qw(
  Aries Taurus Gemini Cancer Leo Virgo
  Libra Scorpio Sagittarius Capricorn Aquarius Pisces
);

my @planets = qw(
  Sun Moon Mercury Venus Mars Jupiter Saturn
  Uranus Neptune Pluto
);

my %opposite_of = (
  Aries       => 'Libra',
  Taurus      => 'Scorpio',
  Gemini      => 'Sagittarius',
  Cancer      => 'Capricorn',
  Leo         => 'Aquarius',
  Virgo       => 'Pisces',
  Libra       => 'Aries',
  Scorpio     => 'Taurus',
  Sagittarius => 'Gemini',
  Capricorn   => 'Cancer',
  Aquarius    => 'Leo',
  Pisces      => 'Virgo',
);

my %rulerships = (
  Sun     => [qw(Leo)],
  Moon    => [qw(Cancer)],
  Mercury => [qw(Gemini Virgo)],
  Venus   => [qw(Taurus Libra)],
  Mars    => [qw(Aries Scorpio)],
  Jupiter => [qw(Sagittarius Pisces)],
  Saturn  => [qw(Capricorn Aquarius)],
  Uranus  => [qw(Aquarius)],
  Neptune => [qw(Pisces)],
  Pluto   => [qw(Scorpio)],
);

# Modern outer-planet exaltation schemes vary a lot, so this keeps the
# widely used traditional exaltations and leaves the outer planets neutral.
my %exaltations = (
  Sun     => 'Aries',
  Moon    => 'Taurus',
  Mercury => 'Virgo',
  Venus   => 'Pisces',
  Mars    => 'Capricorn',
  Jupiter => 'Cancer',
  Saturn  => 'Libra',
);

my %status_for;

for my $planet (keys %rulerships) {
  for my $sign (@{ $rulerships{$planet} }) {
    push @{ $status_for{$planet}{$sign} }, 'Ruler';
    push @{ $status_for{$planet}{ $opposite_of{$sign} } }, 'Detriment';
  }
}

for my $planet (keys %exaltations) {
  my $sign = $exaltations{$planet};
  push @{ $status_for{$planet}{$sign} }, 'Exalted';
  push @{ $status_for{$planet}{ $opposite_of{$sign} } }, 'Fall';
}

print "Planet,Sign,Dignity\n";

for my $planet (@planets) {
  for my $sign (@signs) {
    my $statuses = $status_for{$planet}{$sign};
    my $dignity = $statuses ? join('/', @$statuses) : '-';
    print join(',', $planet, $sign, $dignity), "\n";
  }
}
