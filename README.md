RF Experiments
==============

These are my experiments with cheap [433.92 MHz
receiver/transmitter][devices] devices.

LightwaveRF
-----------

I've successfully decoded LightwaveRF RF data (NOTE: not the data
involving the WifiLink, the actual RF data sent by the LightwaveRF
remotes/etc). This code does that but it's poorly organised (sorry
about that). I'll be writing this up in future, but for now, you can
try decoding your own LightwaveRF captures:

[Online LightwaveRF decoder][onlinedecoder]

To capture some data, install the .ino file onto an Arduino using the
Arduino IDE; connect the receiver's data pin to pin 3, transmitter to pin 4, VCC
to 5V, GND to GND. Then you can either use my `captureanddecode.coffee`
file or you can write your own using the following pseudocode:

    DIVISOR = 0x28;
    connection = serial.connect("/dev/tty..."); # Your Arduino - ttyUSB0 perhaps?
    wait(2 seconds);
    connection.write('D', DIVISOR, 'c'); # Write just these three bytes
    data = connection.read(100000) # Read 100,000 bytes... this may take a while...
    durations = array();
    for each index i value v in bytearray data {
      # Treat `v` as an `unsigned char`
      durations.push(v * DIVISOR);
    }

`durations` will be an array of durations in &mu;s (microseconds). Export
this as a comma separated list and then whack it into the online
decoder:

[Online LightwaveRF decoder][onlinedecoder]

More to come...

Perl
----

There is also a (poorly written right now) perl module, and two example perl scripts
you can run. They assume your arduino device is /dev/ttyACM0 and you have loaded the 
signal\_capture.ino sketch into your arduino.
You will need Modern::Perl and Device::SerialPort installed for your perl.
(Anton Piatek)

License
-------

Released under the [MIT license][].

[devices]: http://www.ebay.co.uk/itm/RF-Wireless-Transmitter-and-Receiver-Link-Kit-Module-433Mhz-For-Remote-Control-/350628314207?pt=UK_Gadgets&hash=item51a3137c5f
[onlinedecoder]: http://benjie.github.com/rf-experiments/
[MIT license]: http://benjie.mit-license.org/
