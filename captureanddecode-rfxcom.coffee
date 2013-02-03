fs = require 'fs'
SerialPort = require('serialport').SerialPort
rfxcom = require 'rfxcom'

delay = (ms, cb) -> setTimeout cb, ms

TRANSMISSION_GAP = 10250
DURATION_TEN = 1250
DURATION_ONE = 250
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
    binStr = bits.join ""
    if binStr.length < 8
      return null
    if outputted.indexOf(binStr) is -1
      outputted.push binStr
      #console.log "#{startIndex} -> #{index} : "
      pretty = binStr.substr(1).replace /1(....)(....)/g, " 1  $1 $2 "
      console.log pretty
      return pretty
    return null

  startData = (index) ->
    startIndex = index
    sensibleData = true
    isHigh = true
    bits = []

  output = []
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
        else if withinErrorMargin(l, DURATION_TEN)
          bits.push "10"
        else
          #console.log "Low duration incorrect: #{l} !~= #{DURATION_ONE} or #{DURATION_ZERO}"
          command = endData(index)
          if command?
            output.push command
      isHigh = !isHigh
    if !sensibleData
      if withinErrorMargin(l, TRANSMISSION_GAP)
        #console.log "Starting logging data."
        startData(index)
  return output

if process.argv[2]?
  filename = process.argv[2]
  filename ?= 'dump.json'
  array = JSON.parse fs.readFileSync filename, 'utf8'
  analyse array
else
  # Capture the data
  rfxtrx = new rfxcom.RfxCom("/dev/tty.usbserial-05VS5FZ1", {debug: false})
  lightwaverf = new rfxcom.Lighting5(rfxtrx, rfxcom.lighting5.LIGHTWAVERF)
  rfxtrx.initialise ->
    console.error("RFXCOM initialised")

    console.error "Opening port..."
    ser = new SerialPort '/dev/tty.usbserial-A6008jYH',
      baudrate: 57600 #76800

    ser.on 'open', ->
      console.error "Port open, capturing..."

      # Throw away first 1.5s of data
      delay 1500, ->


        # What to capture?
        commandsToSend = []
        remote = "0xF30537"
        for unitCode in [1..16]
          commandsToSend.push {remote: remote, id: "ON_#{unitCode}", unitCode: unitCode, command:lightwaverf.ON}
          commandsToSend.push {remote: remote, id: "OFF_#{unitCode}", unitCode: unitCode, command:lightwaverf.ON}
        for mood in [1..3]
          strMood = "MOOD#{mood}"
          commandsToSend.push {remote: remote, id: strMood, command:lightwaverf[strMood]}
        for level in [1..31]
          commandsToSend.push {remote: remote, id: "LEVEL_#{level}", command:lightwaverf.SET_LEVEL, level: level}


        r = null
        okay = null
        b1 = null
        b2 = null
        analogReads = null
        commandToSend = null
        next = ->
          if commandsToSend.length is 0
            console.error "ALL DONE!"
            ser.close()
            rfxtrx.serialport.close()
            delay 2000, ->
              process.exit 0
            return
          commandToSend = commandsToSend.shift()
          ser.write '2'
          delay 0, ->
            remote = commandToSend.remote
            unitCode = commandToSend.unitCode ? "1"
            remote = "#{remote}/#{unitCode}"
            options = {
              command: lightwaverf.ON
            }
            for k in ['command', 'level']
              if commandToSend[k]
                options[k] = commandToSend[k]
            console.log "Performing #{remote} / #{commandToSend.id}"
            lightwaverf.switchOn remote, options
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
              console.error "Analysing"
              commands = analyse analogReads
              fs.writeFileSync __dirname+"/RFX/#{commandToSend.remote}_#{commandToSend.id}", commands.join("\n")
              delay 500, ->
                next()
            r = (b1 << 8) | b2
            analogReads.push(r)
            b1 = b2 = null
          return
        next()
