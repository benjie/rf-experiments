#!/usr/bin/perl
use Modern::Perl; # strict, warnings, v5.10 features

use Lightwave;

my $lwrf = Lightwave->new(port=>"/dev/ttyACM0", debug=>0);
#my $lwrf = Lightwave->new(port=>"/dev/ttyACM0", debug=>0, trace_read_file=>"/tmp/lwrf_recv_raw");

$lwrf->read_serial();
