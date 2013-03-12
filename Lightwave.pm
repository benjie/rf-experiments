#!/usr/bin/perl
# © 2013 Anton Piatek - http://anton.mit-license.org
package Lightwave;

use Modern::Perl;    # strict, warnings, v5.10 features
use Moose;
#use namespace::autoclean;

use Device::SerialPort qw/:PARAM :STAT/;
use Carp qw/confess croak/;
use POSIX qw/floor/;
use IO::Handle;
use Time::HiRes qw(usleep);

has 'port' => (
  is  => 'rw',
  isa => 'Str',
  required=>1,
);
has 'debug' => (
  is  => 'rw',
  isa => 'Bool',
);
has 'trace_read_file' => (
  is  => 'rw',
  isa => 'Str',
);
has 'trace_write_file' => (
  is  => 'rw',
  isa => 'Str',
);

#divisor to send to the arduino
# Try 'a=97' or '(=40'
my $divisor = 40;

# Some timing values from lawrie / ligthwaveRF
# No idea how accurate they are
#MIN_INTERVAL   = 300
#MAX_1_INTERVAL = 550
#MIN_0_INTERVAL = 1000
#MAX_0_INTERVAL = 1400

#Benjies timing values
my $TRANSMISSION_GAP = 10250;
my $DURATION_TEN     = 1250;
#my $DURATION_TEN     = 1040;
my $DURATION_ONE     = 250;
my $DURATION_HIGH    = 250;
my $ERROR_MARGIN     = 150;

my %LW_NIBBLES = (
    "1111 0110" => 0,
    "1110 1110" => 1,
    "1110 1101" => 2,
    "1110 1011" => 3,
    "1101 1110" => 4,
    "1101 1101" => 5,
    "1101 1011" => 6,
    "1011 1110" => 7,
    "1011 1101" => 8,
    "1011 1011" => 9,
    "1011 0111" => "A",
    "0111 1110" => "B",
    "0111 1101" => "C",
    "0111 1011" => "D",
    "0111 0111" => "E",
    "0110 1111" => "F",
);
my %LW_REVERSE_NIBBLES = reverse %LW_NIBBLES;


my %LWRF_hex_to_cmd = (
    "0" => "OFF",
    "1" => "ON",
    "2" => "MOOD",
);
my %LWRF_cmd_to_hex = reverse %LWRF_hex_to_cmd;

my $last_printed    = "";
my $last_printed_ts = "";

my $hex_buffer_sent = "";


my $trace_read_FH;
sub trace_read {
  my ($self, $data) = @_;
  
  if($self->trace_read_file){
    if(! defined $trace_read_FH){
      open( $trace_read_FH, ">", $self->trace_read_file);
      binmode $trace_read_FH;
      $trace_read_FH->autoflush;
    }
    print $trace_read_FH $data;
  }
}

my $trace_write_FH;
sub trace_write {
  my ($self, $data) = @_;

  if($self->trace_write_file){
    if(! defined $trace_write_FH){
      open( $trace_write_FH, ">", $self->trace_write_file);
      binmode $trace_write_FH;
      $trace_write_FH->autoflush;
    }
    print $trace_write_FH $data;
  }
}


my $device;

sub open_serial
{
  my $self = shift;
  
  if( ! defined $device ){
    # Set up the serial port
    # 57600, 81N on the USB ftdi driver
    $device = Device::SerialPort->new($self->port()) || croak "error opening '".$self->port()."'\n$!";
    $device->databits(8);
    $device->baudrate(57600);
    $device->parity("none");
    $device->stopbits(1);

    #flush serial buffer
    say "clearing serial buffer...";
    while ( $device->read(1) ) { }
    usleep(2_000_000);
  }

  return $device;
}

sub set_level
{
  my ( $self, $remoteid, $subunit, $level ) = @_;
  die "level must be between 0 and 31" unless ($level >= 0 && $level <= 31);

  $level = sprintf("%X",$level+0x40);
  $self->send_command_serial($remoteid, $subunit, "ON", $level);
}


sub sendserial{
  my ($self, $data) = @_;
  usleep(50);
  $self->trace_write($data);
  $hex_buffer_sent .= unpack("H*", $data)." ";
  my $device = $self->open_serial();
  my $count_out = $device->write($data);
  #say "$count_out ".unpack("H*",$data);
  die "write failed\n"     unless ($count_out);
  die "write incomplete\n" if ( $count_out != length($data) );
}

sub send_command_serial {
  my ($self, @cmd) = @_;
  my $device = $self->open_serial();

  say join ' ', @cmd;

  #Initialise the arduino to send
  $self->sendserial("D" . chr($divisor) . "s" );

  my $bits = $self->command_to_nibbles(@cmd);
  my @timings = $self->nibbles_to_time_array($bits);

  #send length (as chr?)
  $self->sendserial(chr(scalar @timings));
  
  #send repeats (as chr?)
  $self->sendserial(chr(4));

  #send data timings (as chr?)
  say scalar(@timings) if $self->debug;
  my $count=0;
  my @bytes=();
  foreach my $t (@timings){
  $count++;
    my $int = int($t/$divisor);
    $int = 0 if $int > 255;
    $self->sendserial(chr($int));
  }
  say "buffer sent: $hex_buffer_sent" if $self->debug;

  $hex_buffer_sent = "";
  usleep 500_000;
  print "Checking response:";
  while(1){
    usleep(100);
    my ( $r_count, $data ) = $device->read(3);
#    printf "%x", $data;
 $|=1;
print unpack("H*", $data);
    last if $r_count eq 0;
  }
  print "\n";
}

sub nibbles_to_time_array {
  my ($self, $nibbles) = @_;
  $nibbles =~ s/\s+//g;

  my @timings = ();
  $nibbles .= "1";
  say "nibbles: ".length $nibbles if $self->debug;
  $nibbles =~ s/10/0/g;
  say "nibbles: ".length $nibbles if $self->debug;
  push @timings, $TRANSMISSION_GAP;
  foreach my $c (split(//,$nibbles)){
    push @timings, $DURATION_HIGH;
    push @timings, $DURATION_ONE if $c eq "1";;
    push @timings, $DURATION_TEN if $c eq "0";;
  }
  say "timings: ".(scalar @timings) if $self->debug;
  say join(",",@timings) if $self->debug;
  return @timings;
}


sub read_serial {
    my ($self, $portname) = @_;

    my $device = $self->open_serial();
    my $sensible_data = 0;
    my $isHigh        = 0;
    my $bits          = "";

    #Initialise the arduino to record
    $device->write( "D" . chr($divisor) . "c" );

    open( my $fh, '>', 'dump.csv' ) || die "$!";
    say("ready...");
  
    my $read_bytes = "";

    while (1) {
        my ( $r_count, $b ) = $device->read(1);
        next unless $r_count == 1;

        $read_bytes .= $b;
        my $r = ord($b) * $divisor;
        print $fh "$r, ";

        if ($sensible_data) {
            if ($isHigh) {
                if ( $r > $DURATION_HIGH + $ERROR_MARGIN ) {
                    $isHigh = 0;
                }
            }
            if ( !$isHigh ) {
                if ( $self->inErrMargin( $r, $DURATION_ONE ) ) {
                    $bits .= "1";
                }
                elsif ( $self->inErrMargin( $r, $DURATION_TEN ) ) {
                    $bits .= "10";
                }
                else {
                    #reset data
                    $sensible_data = 0;
                    $self->print_data($bits);
                    $bits = "";
                    $self->trace_read($read_bytes);
                    $read_bytes = "";
                }
            }
            $isHigh = !$isHigh;
        }
        if ( !$sensible_data ) {
            if ( $self->inErrMargin( $r, $TRANSMISSION_GAP ) ) {
                #reset data
                $sensible_data = 1;
                $isHigh        = 1;
                $bits          = "";
                $read_bytes = "";
            }
        }
    }
}

sub command_to_nibbles
{
  my ( $self, $remoteid, $subunit, $command, $level ) = @_;
  return $self->hexarray_to_formatted_nibbles( 
      split(//, join('',$level, $self->LWRF_subunit_to_hex($subunit), $self->LWRF_cmd_to_hex($command), $remoteid) ) 
    );
}

sub nibbles_to_hexarray
{
    my ($self, $data) = @_;

    #Each packet should have 91 bits
    return unless length($data) == 91;

    my $formatted_data = substr $data, 1;
    $formatted_data =~ s/1(.{4})(.{4})/1 $1 $2 /g;
    print "1 $formatted_data\n" if $self->debug;

    my @nibbles = $formatted_data =~ m/1 \s ([01]{4} \s [01]{4} )/gx;
    my @hex_bytes = ();
    foreach my $nibble (@nibbles) {
        push @hex_bytes, $LW_NIBBLES{$nibble};
    }
    return @hex_bytes;
}

sub hexarray_to_formatted_nibbles
{
  my ($self, @data) = @_;
  return unless @data == 10; 
  
  #start with a 1
  my $nibblestring = "1";

  #append each pair of bytes as nibbles, preceeded by a 1
  my $count = 0;
  foreach my $byte (@data){
    $nibblestring .= " 1 ".$LW_REVERSE_NIBBLES{$byte};
  }
  return $nibblestring;
}

sub unpack_data {
    my ($self, $data) = @_;

    #Each packet should have 91 bits
    return unless length($data) == 91;

    my @hex_bytes = $self->nibbles_to_hexarray($data);
    say "0x",@hex_bytes if $self->debug;

    #Notes: Level 00 used for on/off
    # 		level 40 sometimes sent as a repeat for off
    #		Level C0 used on button D4 for "all off"
    #		level 82 used on button D4 with cmd MOOD for mood (mood 2?)
    #		level 02 used on button D4 with cmd MOOD to set current levels as mood (mood 2?)
    #		level BF used to increase brightness
    #		level A0 used to decrease brightness
    my $level   = $hex_bytes[0] . $hex_bytes[1];
    my $subunit = $self->LWRF_hex_to_subunit( $hex_bytes[2] );
    my $command = $self->LWRF_hex_to_cmd( $hex_bytes[3] );
    my $remoteid =
        $hex_bytes[4]
      . $hex_bytes[5]
      . $hex_bytes[6]
      . $hex_bytes[7]
      . $hex_bytes[8]
      . $hex_bytes[9];

    return ( $remoteid, $subunit, $command, $level );
}

sub print_data {
    my ($self, $data) = @_;
    return unless $data;
    return unless length($data) > 8;

    #Skip if we recently printed the same thing
    return if ( $last_printed eq $data && ( time() - $last_printed_ts < 2 ) );
    $last_printed_ts = time();
    $last_printed    = $data;

    #Each packet should have 91 bits
    return unless length($data) == 91;

    #	my $formatted_string = "";
    #	my $count = 1;
    #	foreach my $c (split(//, $data)){
    #		$formatted_string .= $c;
    #		$formatted_string .= " " unless ($count % 4);
    #		$count++;
    #	}
    #	print "$formatted_string\n" if $self->debug;
    print unpack( 'H*', pack( 'B*', $data ) ) . "\t " . length($data) . "\n"
      if $self->debug;

    my ( $remoteid, $subunit, $command, $level ) = $self->unpack_data($data);

    printf "button: %2s cmd: %4s level: %2s id: %s\n", $subunit, $command,
      $level, $remoteid;
}

sub inErrMargin {
    my ( $self, $test, $expected ) = @_;
    my $errMargin = $ERROR_MARGIN + $expected / 8;
    return ( $expected - $errMargin < $test && $test < $expected + $errMargin );
}

sub LWRF_hex_to_cmd {
    my ($self, $hex) = @_;
    return $LWRF_hex_to_cmd{$hex} if ( exists $LWRF_hex_to_cmd{$hex} );
    confess "unknown LWRF command '$hex'";
}

sub LWRF_cmd_to_hex {
    my ($self, $cmd) = @_;
    $cmd = uc $cmd;
    return $LWRF_cmd_to_hex{$cmd} if ( exists $LWRF_cmd_to_hex{$cmd} );
    confess "unknown LWRF command '$cmd'";
}

sub LWRF_hex_to_subunit {
    my ($self, $hex)   = @_;
    my $dec     = hex($hex);
    my $quot    = ( $dec % 4 ) + 1;
    my $div     = floor( $dec / 4 );
    my $sel     = chr( ord("A") + $div );
    my $subunit = $sel . $quot;
    confess "unknown subunit '$subunit' (fom hex '$hex')"
      unless $subunit =~ /[A-D][1-4]/;
    return $subunit;
}

sub LWRF_subunit_to_hex {
    my ($self, $subunit) = @_;
    $subunit = uc $subunit;
    if ( $subunit =~ /([A-D])([1-4])/ ) {
        my $sel = $1;
        my $num = $2;
        $sel = ord($1) - ord("A");
        $num--;
        return sprintf "%X", ( 4 * $sel ) + $num;
    }
    else {
        confess "unknown subunit '$subunit'";
    }
}

__PACKAGE__->meta->make_immutable;

1;
