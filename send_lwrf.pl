#!/usr/bin/perl
use Modern::Perl; # strict, warnings, v5.10 features

use Lightwave;

my $lwrf = Lightwave->new(port=>"/dev/ttyACM0", debug=>0);


$lwrf->set_level("F0EB8E", "A1", 31);
$lwrf->set_level("F0EB8E", "A1", 13);
$lwrf->send_command_serial("F0EB8E","D4", "OFF", "C0");

#$lwrf->send_command_serial("F0EB8E","A2", "OFF", "00");
#$lwrf->send_command_serial("F0EB8E","A2", "ON", "FF");
$lwrf->send_command_serial("F0EB8E","A1", "ON", "00");
$lwrf->send_command_serial("F0EB8E","A2", "ON", "00");
$lwrf->send_command_serial("F0EB8E","A3", "ON", "00");
$lwrf->send_command_serial("F0EB8E","A3", "ON", "00");
#$lwrf->send_command_serial("F0EB8E","A2", "OFF", "40");
#all off
$lwrf->send_command_serial("F0EB8E","D4", "OFF", "C0");
