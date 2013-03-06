#!/usr/bin/perl
use Modern::Perl; # strict, warnings, v5.10 features

use lightwave;


lightwave::set_level("F0EB8E", "A1", 31);
lightwave::set_level("F0EB8E", "A1", 13);
lightwave::send_command_serial("/dev/ttyACM0", "F0EB8E","D4", "OFF", "C0");
exit;

#lightwave::send_command_serial("/dev/ttyACM0", "F0EB8E","A2", "OFF", "00");
#lightwave::send_command_serial("/dev/ttyACM0", "F0EB8E","A2", "ON", "FF");
lightwave::send_command_serial("/dev/ttyACM0", "F0EB8E","A1", "ON", "00");
lightwave::send_command_serial("/dev/ttyACM0", "F0EB8E","A2", "ON", "00");
lightwave::send_command_serial("/dev/ttyACM0", "F0EB8E","A3", "ON", "00");
lightwave::send_command_serial("/dev/ttyACM0", "F0EB8E","A3", "ON", "00");
#lightwave::send_command_serial("/dev/ttyACM0", "F0EB8E","A2", "OFF", "40");
#all off
lightwave::send_command_serial("/dev/ttyACM0", "F0EB8E","D4", "OFF", "C0");
foreach (reverse 0..255){
  my $level = sprintf("%X",$_);
  $level = "0$level" if length($level) < 2;
  lightwave::send_command_serial("/dev/ttyACM0", "F0EB8E","A1", "ON", $level);
}
