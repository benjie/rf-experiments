fs = require 'fs'
SerialPort = require('serialport').SerialPort
LightwaveRF = require './lightwaverf.coffee'

delay = (ms, cb) -> setTimeout cb, ms

TRANSMISSION_GAP = 10250
DURATION_TEN = 1250
DURATION_ONE = 250
DURATION_HIGH = 250

ERROR_MARGIN = 150

divisor = 40
analogReads = []

withinErrorMargin = (val, expected) ->
  margin = ERROR_MARGIN + expected/8
  return expected-margin < val < expected+margin

analyse = ->
  results = LightwaveRF.decode analogReads
  stopIndex = null
  for result in results when result.valid
    console.log "DATA: #{result.pretty}"
    console.log "  meaning: Remote: #{result.remoteId}, subunit: #{result.subunit} (#{result.subunitName}), command: #{result.command} (#{result.commandName}), parameter: #{result.parameter} (#{result.level ? "-"})"
    console.log ""
    stopIndex = result.stopIndex

  # Clear memory every time we get a LightwaveRF command
  if stopIndex ? 0 > 0
    analogReads.splice(0, stopIndex)

  # Clear periodically anyway
  checkFrequency = 500
  amountToKeep = 2000
  if analogReads.length % checkFrequency is 0
    if analogReads.length > amountToKeep
      analogReads = analogReads.slice(-amountToKeep)

  return

if process.argv[2]?
  filename = process.argv[2]
  filename ?= 'dump.json'
  array = JSON.parse fs.readFileSync filename, 'utf8'
  analyse array
else
  # Capture the data

  console.error "Opening port..."
  ser = new SerialPort '/dev/ttyACM0',
    baudrate: 57600 #76800

  ser.on 'open', ->
    console.error "Port open, capturing..."

    # Throw away first 1.5s of data
    delay 1500, ->
      toSend = new Buffer(3)
      toSend[0] = 'D'.charCodeAt(0)
      toSend[1] = divisor
      toSend[2] = 'c'.charCodeAt(0)
      ser.write toSend
      r = 0
      okay = 0

      ser.on 'data', (data) ->
        for i in [0...data.length]
          val = data.readUInt8 i
          val *= divisor
          analogReads.push(val)
          analyse()
        return
