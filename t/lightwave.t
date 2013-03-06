#!/usr/bin/perl
use Modern::Perl;    # strict, warnings, v5.10 features

use lightwave;

use Test::More tests=>50;

my @data =
( 
  [ 
    "1 1 1101 1110 1 1111 0110 1 1110 1101 1 1111 0110 1 0110 1111 1 1111 0110 1 0111 0111 1 0111 1110 1 1011 1101 1 0111 0111",
    "4020F0EB8E",
    ["F0EB8E","A3","OFF","40"]
  ],
  [
    "1 1 1111 0110 1 1111 0110 1 1111 0110 1 1111 0110 1 0110 1111 1 1111 0110 1 0111 0111 1 0111 1110 1 1011 1101 1 0111 0111",
    "0000F0EB8E",
    ["F0EB8E","A1", "OFF", "00"]
  ],
  [
    "1 1 1101 1110 1 1111 0110 1 1111 0110 1 1111 0110 1 0110 1111 1 1111 0110 1 0111 0111 1 0111 1110 1 1011 1101 1 0111 0111",
    "4000F0EB8E",
    ["F0EB8E","A1","OFF","40"]
  ],
  [
    "1 1 1111 0110 1 1111 0110 1 1110 1110 1 1111 0110 1 0110 1111 1 1111 0110 1 0111 0111 1 0111 1110 1 1011 1101 1 0111 0111",
    "0010F0EB8E",
    ["F0EB8E", "A2", "OFF", "00"]
  ],
  [
    "1 1 1101 1110 1 1111 0110 1 1110 1110 1 1111 0110 1 0110 1111 1 1111 0110 1 0111 0111 1 0111 1110 1 1011 1101 1 0111 0111",
    "4010F0EB8E",
    ["F0EB8E","A2","OFF","40"]
  ],
  [
    "1 1 1111 0110 1 1111 0110 1 1110 1011 1 1110 1110 1 0110 1111 1 1111 0110 1 0111 0111 1 0111 1110 1 1011 1101 1 0111 0111",
    "0031F0EB8E",
    ["F0EB8E","A4","ON","00"]
  ],
  [
    "1 1 1111 0110 1 1111 0110 1 1110 1101 1 1110 1110 1 0110 1111 1 1111 0110 1 0111 0111 1 0111 1110 1 1011 1101 1 0111 0111",
    "0021F0EB8E",
    ["F0EB8E","A3","ON","00"]
  ],
  [
    "1 1 1111 0110 1 1111 0110 1 0111 0111 1 1110 1110 1 0110 1111 1 1111 0110 1 0111 0111 1 0111 1110 1 1011 1101 1 0111 0111",
    "00E1F0EB8E",
    ["F0EB8E","D3","ON","00"]
  ],
  #All off 
  [
    "1 1 0111 1101 1 1111 0110 1 0110 1111 1 1111 0110 1 0110 1111 1 1111 0110 1 0111 0111 1 0111 1110 1 1011 1101 1 0111 0111",
    "C0F0F0EB8E",
    ["F0EB8E","D4","OFF","C0"]
  ],
  [
    "1 1 1011 1101 1 1110 1101 1 0110 1111 1 1110 1101 1 0110 1111 1 1111 0110 1 0111 0111 1 0111 1110 1 1011 1101 1 0111 0111",
    "82F2F0EB8E",
    ["F0EB8E","D4","MOOD", "82"]
  ],
);

foreach my $row (@data){
  my $origbits = my $bits = @$row[0];
  $bits =~ s/\s+//g;
  my $hex = @$row[1];
  my $parsed = @$row[2];

  is(join('',lightwave::nibbles_to_hexarray($bits)), $hex, "nibbles to hex");
  is_deeply([lightwave::unpack_data($bits)], $parsed, "unpack data");
  is( lightwave::hexarray_to_formatted_nibbles(split(//,$hex)), $origbits, "hexarray to formatted nibbles");
  is(lightwave::command_to_nibbles(@$parsed), $origbits, "command_to_nibbles");
}



is( lightwave::LWRF_hex_to_subunit("0"), "A1", "hex_to_subunit(0)");
is( lightwave::LWRF_subunit_to_hex("A1"), "0" , "LWRF_subunit_to_hex(A1)");
is( lightwave::LWRF_hex_to_subunit("F"), "D4", "hex_to_subunit(F)");
is( lightwave::LWRF_subunit_to_hex("D4"), "F" , "LWRF_subunit_to_hex(D4)");

is( lightwave::LWRF_cmd_to_hex("OFF"), "0" , "LWRF_cmd_to_hex(OFF)");
is( lightwave::LWRF_hex_to_cmd("0"), "OFF", "LWRF_hex_to_cmd(0)");
is( lightwave::LWRF_cmd_to_hex("ON"), "1" , "LWRF_cmd_to_hex(ON)");
is( lightwave::LWRF_hex_to_cmd("1"), "ON", "LWRF_hex_to_cmd(1)");
is( lightwave::LWRF_cmd_to_hex("MOOD"), "2" , "LWRF_cmd_to_hex(MOOD)");
is( lightwave::LWRF_hex_to_cmd("2"), "MOOD", "LWRF_hex_to_cmd(2)");

