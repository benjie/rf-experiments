fs = require 'fs'

TRANSMISSION_GAP = 10250
DURATION_ONE = 1250
DURATION_ZERO = 250
DURATION_HIGH = 250

ERROR_MARGIN = 150

withinErrorMargin = (val, expected) ->
  margin = ERROR_MARGIN + expected/8
  return expected-margin < val < expected+margin

filename = process.argv[2]
filename ?= 'dump.json'
array = JSON.parse fs.readFileSync filename, 'utf8'

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
  if binStr.length < 4
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

