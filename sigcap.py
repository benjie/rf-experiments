#!/usr/bin/python

import time
import serial # easy_install pyserial
import matplotlib.pyplot as plt # easy_install matplotlib
import numpy as np

ser = serial.Serial(
  port = '/dev/tty.usbserial-A6008jEU',
  baudrate = 250000,
  )

time.sleep(1.5)
ser.flush()
print "Capturing..."
ser.write('2')

r = 0
analog_reads = [];
read = 5002
while read > 0:
  read -= 1
  r = ord(ser.read(1))
  if (r >> 7) & 1:
    break
  for i in range(7):
    v = (r >> i) & 1
    analog_reads.append(v)
ser.close()

print "Plotting"
#plt.plot(analog_times, analog_reads)
ind = np.arange(len(analog_reads))    # the x locations for the groups
plt.bar(ind, analog_reads, 1)
plt.show()
