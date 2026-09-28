#!/usr/bin/perl -wT

use strict;
use Time::Local;
use lib qw();
use JSON::PP qw(encode_json decode_json);
use Data::Dumper;
use Math::Trig;
use DBI;
use FindBin qw($Bin);






my $online = shift @ARGV;

sub respond_json {
	my ($payload, $exit_code) = @_;

	if (exists $ENV{GATEWAY_INTERFACE}) {
		print "Content-Type: application/json\n\n";
	}

	print encode_json($payload);
	exit($exit_code // 0);
}

sub parse_birthday {
	my ($value) = @_;

	if (!defined $value || $value !~ /\A(\d{4}):(\d{1,2}):(\d{1,2})\z/) {
		respond_json({ error => 'Invalid date input. Expected YYYY:MM:DD.' }, 1);
	}

	my ($year, $month, $day) = ($1, $2, $3);

	if ($month < 1 || $month > 12 || $day < 1 || $day > 31) {
		respond_json({ error => 'Invalid calendar date provided.' }, 1);
	}

	return ($year, $month, $day);
}

sub untaint_path {
	my ($value) = @_;

	return if !defined $value;
	return $1 if $value =~ /\A([A-Za-z0-9_\/.\-]+)\z/;
	return;
}

sub resolve_data_file {
	my @raw_candidates = (
		$ENV{PLANETS_JSON},
		"$Bin/Planets.json",
		"/home/misfitx/astro/public_html/Planets.json",
	);
	my @candidates = ();

	foreach my $path (@raw_candidates) {
		my $clean_path = untaint_path($path);
		next if !defined $clean_path || !-f $clean_path;
		push @candidates, $clean_path;
	}

	if (!@candidates) {
		respond_json({ error => 'Unable to locate Planets.json data file.' }, 1);
	}

	return $candidates[0];
}








#########		Set Persons Birthday here. Jan = 0;

sub Me {

my $second              = "00";
my $minute              = "42";
my $hour                = "12";


my ($year, $month, $day) = parse_birthday($online);


my $mm = $month - 1;

my $birthday    = timelocal($second, $minute, $hour, $day, $mm, $year);

return $birthday;


}


my $file	= resolve_data_file();

my $json_text	= do {
	open (my $FH, $file) || respond_json({ error => "Unable to open $file: $!" }, 1);

local $/;
<$FH>

};

# my %data = ();

my $data = eval { decode_json($json_text) };

if ($@) {
	respond_json({ error => 'Unable to decode Planets.json data.' }, 1);
}



# my @inner = qw( Mercury Venus Earth Mars );
# my @outer = qw( Jupiter Saturn Uranus Neptune Pluto );


my @list	= (0..360);
my %hash	= ();


foreach my $item (@list) {
	my $var		= $item / 360;
	$var		= sprintf("%.2f", $var);
	$hash{$var} = $item;
#	print "$var\n";
}





###############################################
my $pi			= 3.141592653589;
my $JDEpoch		= "2447891.5";
my $Time		= time;

my $jd		= jtime($Time);
my $days	= currentJD($jd, $JDEpoch);
my $time	= time;
my $dob		= Me();

my $dobJ	= jtime($dob);







my $Moon   = &Moon($jd, $dobJ);
my $Mercury = &Mercury($jd, $dobJ);
my $Venus = &Venus($jd, $dobJ);
my $Earth = &Earth($jd, $dobJ);
my $Mars  = &Mars($jd, $dobJ);
my $Jupiter = &Jupiter($jd, $dobJ);
my $Saturn  = &Saturn($jd, $dobJ);
my $Uranus  = &Uranus($jd, $dobJ);
my $Neptune = &Neptune($jd, $dobJ);
my $Pluto   = &Pluto($jd, $dobJ);

my ($input_year, $input_month, $input_day) = parse_birthday($online);

my %response = (
	input => {
		year => $input_year,
		month => $input_month,
		day => $input_day,
	},
	planets => {
		moon => 0 + $Moon,
		mercury => 0 + $Mercury,
		venus => 0 + $Venus,
		earth => 0 + $Earth,
		mars => 0 + $Mars,
		jupiter => 0 + $Jupiter,
		saturn => 0 + $Saturn,
		uranus => 0 + $Uranus,
		neptune => 0 + $Neptune,
		pluto => 0 + $Pluto,
	},
);

respond_json(\%response, 0);






# print "Moon: $Moon\nMercury: $Mercury\nVenus: $Venus\nEarth: $Earth\nMars: $Mars\nJupiter: $Jupiter\nSaturn: $Saturn\nURanus: $Uranus\nNeptune: $Neptune\nPluto: $Pluto\n\n";

#moon
#mercury

sub Mercury {
	my $jd = shift;
	my $dobJ = shift;
	my $planet = "Mercury";
		my ($at, $d1) = PlanetX($jd, $dobJ, $planet);
		return $at;
}
#venus
sub Venus {
	my $jd = shift;
	my $dobJ = shift;
	my $planet = "Venus";
		my ($at, $d1) = PlanetX($jd, $dobJ, $planet);
		return $at;
}

#Earth
sub Earth {
	my $jd = shift;
	my $dobJ = shift;
	my $planet = "Earth";
		my ($at, $d1) = PlanetX($jd, $dobJ, $planet);
		return $at;
}

#mars
sub Mars {
	my $jd = shift;
	my $dobJ = shift;
	my $planet = "Mars";
		my ($at, $d1) = PlanetX($jd, $dobJ, $planet);
		return $at;
}
#jupiter
sub Jupiter {
	my $jd = shift;
	my $dobJ = shift;
	my $planet = "Jupiter";
		my ($at, $d1) = PlanetX($jd, $dobJ, $planet);
		return $at;
}
#saturn
sub Saturn {
	my $jd = shift;
	my $dobJ = shift;
	my $planet = "Saturn";
		my ($at, $d1) = PlanetX($jd, $dobJ, $planet);
		return $at;
}
#uranus
sub Uranus {
	my $jd = shift;
	my $dobJ = shift;
	my $planet = "Uranus";
		my ($at, $d1) = PlanetX($jd, $dobJ, $planet);
		return $at;
}
#neptune
sub Neptune {
	my $jd = shift;
	my $dobJ = shift;
	my $planet = "Neptune";
		my ($at, $d1) = PlanetX($jd, $dobJ, $planet);
		return $at;
}
#pluto
sub Pluto {
	my $jd = shift;
	my $dobJ = shift;
	my $planet = "Pluto";
		my ($at, $d1) = PlanetX($jd, $dobJ, $planet);
		return $at;
}

















sub Moon {
	my $jd = shift;
	my $dobJ = shift;


# my $moon		= "27.321661";				# Sidereal
my $moon		= "29.530589";				# synodic


my $MDay = $jd - $dobJ;


my $md	= $MDay / $moon;

# print "Moon: $md\n";

return $md;

}


sub PlanetX {
	my $Dday	= shift;
	my $dob		= shift;
	my $planet	= shift;


	my $days = $Dday - $dob;	

	# days / orbit = where
	my $orbit	= $data->{$planet}[0]{orbit};
	my $set		= $days / $orbit;
#	print "$set\t";


	my $np	= (360 / 365.256363) * $set;

#	print "NP: $np\t";

	my $e	= $data->{$planet}[0]{Long};
	my $m	= $data->{$planet}[0]{LongP};
	my $a	= $data->{$planet}[0]{Semi};
	my $ee	= $data->{$planet}[0]{Eccent};


#	print "Planet: $planet; $e, $m, $a, $ee\n";


	return($set, $np);



}






sub currentJD {
	my $jd	= shift;
	my $ep	= shift;
	my $now	= $jd - $ep;
	return $now;
}



sub jtime {
	my $t = shift;
	my ($julian);
	$julian = ($t / 86400) + 2440587.5;	# (seconds /(seconds per day)) + julian date of epoch
	return ($julian);
}

sub fixDegree {
	my $var = shift;

	while(1) { last if $var >=   0; $var += 360 }
	while(1) { last if $var < 360; $var -= 360 }

	return $var;

}

sub todeg	{ return ($_[0] * (180.0 / $pi)); }						# rad->deg

sub num2dec {
        my $var = shift;
        if ( $var >= 0) {
                my $x =  abs($var);
                my $f1 = floor($x);
                my $f2 =  $x - $f1;
                return $f2;
        } else {
                my $x =  abs($var);
                my $f1 = floor($x);
                my $f2 =  $x - $f1;
                my $f5 = -$f2;
                return $f5;
        }
}


sub floor {
  my $val   = shift;
  my $neg   = $val < 0;
  my $asint = int($val);
  my $exact = $val == $asint;

  return ($exact ? $asint : $neg ? $asint - 1 : $asint);
}






exit(0);
