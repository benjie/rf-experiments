#!/usr/bin/python

import sys
import time
import serial # easy_install pyserial
import matplotlib.pyplot as plt # easy_install matplotlib
import numpy as np
import simplejson

if len(sys.argv >= 2):
  readFromFile = sys.argv[1]
  f = open(readFromFile, 'r')
  analog_reads = simplejson.load(f)
  f.close()
else:
  f = open('dump.json', 'w')

  ser = serial.Serial(
    port = '/dev/tty.usbserial-A6008jEU',
    baudrate = 76800,
  )

  time.sleep(1.5)
  ser.flush()
  while ser.inWaiting() > 0:
    print "Flushing buffer"
    ser.read(1)
  print "Capturing..."
  ser.write('2')

  r = 0
  analog_reads = [];
  while 1:
    b1 = ord(ser.read(1))
    b2 = ord(ser.read(1))
    if b1 is 0xFF and b2 is 0xFF:
      break
    r = (b1 << 8) | b2
    analog_reads.append(r)
    print ".",

  ser.close()

  simplejson.dump(analog_reads, f)
  f.close()

print "Plotting"
#plt.plot(analog_times, analog_reads)
#plt.plot(range(len(analog_reads)), analog_reads)
ind = np.arange(len(analog_reads))    # the x locations for the groups
plt.bar(ind, analog_reads, 1)
plt.show()
