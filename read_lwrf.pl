#!/usr/bin/perl
use Modern::Perl; # strict, warnings, v5.10 features

use lightwave;

lightwave::read_serial("/dev/ttyACM0");
