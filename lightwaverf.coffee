###
LightwaveRF by @Benjie
###

TRANSMISSION_GAP = 10250
DURATION_TEN = 1250
DURATION_ONE = 250
DURATION_HIGH = 250
ERROR_MARGIN = 150

commands =
  OFF: 0
  ON: 1
  MOOD: 2

commandNames = []
for k, v of commands
  commandNames[v] = k

withinErrorMargin = (val, expected) ->
  margin = ERROR_MARGIN + expected/8
  return expected-margin < val < expected+margin

###
`analogReads` is an array of durations in us (microseconds).

If the data you pass has been divided by a divisor (e.g. 40) then pass this
divisor via the `options` hash, e.g. `options.divisor=40`
###
decodeLightwaveRF = (analogReads, options={}) ->
  {divisor} = options
  divisor ?= 1

  results = []

  sensibleData = false
  isHigh = false
  bits = null
  startIndex = null
  stopIndex = null

  endData = (index) ->
    stopIndex = index
    sensibleData = false
    binStr = bits.join ""
    if binStr.length < 8
      return
    raw = binStr
    pretty = raw.substr(0, 1) + " " + raw.substr(1).replace /1(....)(....)/g, " 1  $1 $2 "
    data = raw.substr(1).replace /1(........)/g, "$1"
    results.push
      startIndex: startIndex
      stopIndex: stopIndex
      raw: raw
      pretty: pretty
      data: data

  startData = (index) ->
    startIndex = index
    sensibleData = true
    isHigh = true
    bits = []

  for l, index in analogReads
    l *= divisor
    if sensibleData
      if isHigh
        if l > DURATION_HIGH + ERROR_MARGIN
          isHigh = false
      if !isHigh
        if withinErrorMargin(l, DURATION_ONE)
          bits.push "1"
        else if withinErrorMargin(l, DURATION_TEN)
          bits.push "10"
        else
          endData(index)
      isHigh = !isHigh
    if !sensibleData
      if withinErrorMargin(l, TRANSMISSION_GAP)
        startData(index)

  nibbleLookup = [
    "11110110"
    "11101110"
    "11101101"
    "11101011"
    "11011110"
    "11011101"
    "11011011"
    "10111110"
    "10111101"
    "10111011"
    "10110111"
    "01111110"
    "01111101"
    "01111011"
    "01110111"
    "01101111"
  ]

  subunitNameLookup = []
  for letter in "ABCD".split("")
    for number in [1..4]
      subunitNameLookup.push letter+number

  for result in results
    str = result.data
    nibbles = []
    while str.length >= 8
      byte = str.substr(0, 8)
      str = str.substr(8)
      nibble = nibbleLookup.indexOf(byte)
      if nibble < 0
        break
      nibbles.push nibble

    result.nibbles = nibbles
    if nibbles.length >= 10
      result.valid = true
      result.parameter = nibbles[0] << 4 + nibbles[1]
      if result.parameter >= 0x80
        result.level = result.parameter - 0x80
      result.subunit = nibbles[2]
      result.subunitName = subunitNameLookup[nibbles[2]]
      result.command = nibbles[3]
      result.commandName = commandNames[nibbles[3]]
      id = 0
      for i in [0..5]
        id += (nibbles[4+i]) << (4 * (5-i))
      result.remoteIdInt = id
      result.remoteId = "0x"+id.toString(16).toUpperCase()

  return results

exports.decode = decodeLightwaveRF
exports.commands = commands
exports.commandNames = commandNames
