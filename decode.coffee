fs = require 'fs'
decodeLightwaveRF = require('./lightwaverf').decode

filename = process.argv[2]
filename ?= 'dump.json'
array = JSON.parse fs.readFileSync filename, 'utf8'
array.push 0 # Definitely terminate the data

results = decodeLightwaveRF(array)

lastData = null
repeatCount = 0
outputRepeats = ->
  if repeatCount > 0
    console.log "Last record repeated #{repeatCount} times"
  repeatCount = 0
  console.log "" if lastData?

for result in results when result.valid
  if lastData is result.data
    repeatCount++
  else
    outputRepeats()
    lastData = result.data
    console.log "DATA: #{result.pretty}"
    console.log "  meaning: Remote: #{result.remoteId}, subunit: #{result.subunit} (#{result.subunitName}), command: #{result.command} (#{result.commandName}), parameter: #{result.parameter} (#{result.level ? "-"})"

outputRepeats()
