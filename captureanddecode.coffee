fs = require 'fs'
SerialPort = require('serialport').SerialPort

delay = (ms, cb) -> setTimeout cb, ms

TRANSMISSION_GAP = 10250
DURATION_ONE = 1250
DURATION_ZERO = 250
DURATION_HIGH = 250

ERROR_MARGIN = 150

withinErrorMargin = (val, expected) ->
  margin = ERROR_MARGIN + expected/8
  return expected-margin < val < expected+margin

analyse = (array) ->
  sensibleData = false
  isHigh = false
  bits = null
  outputted = []
  startIndex = null

  endData = (index) ->
    sensibleData = false
    #bits.shift 1
    bits.unshift "0"
    binStr = bits.join ""
    if binStr.length < 8
      return
    if outputted.indexOf(binStr) is -1
      outputted.push binStr
      #console.log "#{startIndex} -> #{index} : "
      console.log binStr.replace /(....)/g, "$1 "

  startData = (index) ->
    startIndex = index
    sensibleData = true
    isHigh = true
    bits = []

  for l, index in array
    if sensibleData
      if isHigh
        #if !withinErrorMargin(l, DURATION_HIGH)
        if l > DURATION_HIGH + ERROR_MARGIN
          isHigh = false
          #console.log "High duration incorrect: #{l} !~= #{DURATION_HIGH}"
          #endData()
      if !isHigh
        if withinErrorMargin(l, DURATION_ONE)
          bits.push "1"
        else if withinErrorMargin(l, DURATION_ZERO)
          bits.push "0"
        else
          #console.log "Low duration incorrect: #{l} !~= #{DURATION_ONE} or #{DURATION_ZERO}"
          endData(index)
      isHigh = !isHigh
    if !sensibleData
      if withinErrorMargin(l, TRANSMISSION_GAP)
        #console.log "Starting logging data."
        startData(index)

if process.argv[2]?
  filename = process.argv[2]
  filename ?= 'dump.json'
  array = JSON.parse fs.readFileSync filename, 'utf8'
  analyse array
else
  # Capture the data

  console.log "Opening port..."
  ser = new SerialPort '/dev/tty.usbserial-A6008jEU',
    baudrate: 57600 #76800

  ser.on 'open', ->
    console.log "Port open, capturing..."

    # Throw away first 1.5s of data
    delay 1500, ->
      ser.write '2'
      r = 0
      okay = 0
      b1 = null
      b2 = null
      analogReads = []

      ser.on 'data', (data) ->
        for i in [0...data.length]
          val = data.readUInt8 i
          if okay < 2
            if val isnt 0xFF
              okay = 0
            else
              okay++
            continue
          if b1 is null
            b1 = val
            continue
          else
            b2 = val
          if b1 is 0xFF and b2 is 0xFF
            ser.close()
            console.log "Analysing"
            analyse analogReads
          r = (b1 << 8) | b2
          analogReads.push(r)
          b1 = b2 = null
        return
