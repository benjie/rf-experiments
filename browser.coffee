###
This file is to be ran on the browser.
###

LightwaveRF = require('./lightwaverf.coffee')


formEl = null
outputEl = null
dataEl = null

output = (results) ->
  html = ""
  lastData = null
  repeatCount = 0
  outputRepeats = ->
    if repeatCount > 0
      html += "Repeats: <span class='data'>#{repeatCount}</span><br />"
    repeatCount = 0
    html += "</div>" if lastData?

  for result in results when result.valid
    if lastData is result.data
      repeatCount++
    else
      outputRepeats()
      lastData = result.data
      html += "<div class='entry'>"
      html += "<tt>#{result.pretty}</tt> <span class='debug'>from #{result.startIndex}..#{result.stopIndex}</span><br />"
      html += "Remote: <span class='data'>#{result.remoteId}</span>, subunit: <span class='data'>#{result.subunit}</span> <span class='debug'>(#{result.subunitName})</span>, command: <span class='data'>#{result.command}</span> <span class='debug'>(#{result.commandName})</span>, parameter: <span class='data'>#{result.parameter}</span> <span class='debug'>(#{result.level ? "-"})</span><br />"

  outputRepeats()

  outputEl.innerHTML = html

window.addEventListener 'DOMContentLoaded', ->
  formEl = document.getElementById('input')
  outputEl = document.getElementById('output')
  dataEl = document.getElementById('data')

  formEl.onsubmit = (e) ->
    e.preventDefault()

    data = dataEl.value.replace /[^0-9,]/,""
    data = data.split(",")

    results = LightwaveRF.decode data

    console.log results

    output(results)

    return false
