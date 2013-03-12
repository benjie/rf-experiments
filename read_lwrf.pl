#!/usr/bin/perl
use Modern::Perl; # strict, warnings, v5.10 features

use Lightwave;

my $lwrf = Lightwave->new(port=>"/dev/ttyACM0", debug=>1);

$lwrf->read_serial();
