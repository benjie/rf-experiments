FILTER_MODE = 1
CANVAS_WIDTH = 1280
CANVAS_HEIGHT = 200
MAX_LENGTH = 20
MIN_RANGE = 700
REQUIRED_LENGTH = 80
all = []
filtered = []
okay = []
pending = []
okayLength = 0
canvas = undefined
ctx1 = undefined
ctx2 = undefined

similar = (ref, val) ->
  if Array.isArray ref
    for rVal in ref
      if !similar(rVal, val)
        return false
    return true
  #return (val > ref - DIFF && val < ref + DIFF);
  diff = Math.abs(val - ref)
  range = 100
  range += diff * 0.02
  return diff < range
  #Math.min(200, Math.max(ref / 6, 50))

range = (arr) ->
  if arr.length is 0
    return 0
  min = Math.min.apply Math, arr
  max = Math.max.apply Math, arr
  return max - min

onload = ->
  canvas = document.getElementsByTagName("canvas")
  ctx1 = canvas[0].getContext("2d")
  ctx2 = canvas[1].getContext("2d")
  ctx1.fillColor = "red"
  ctx2.fillColor = "black"
  socket = new io.connect(window.location.protocol + "//" + window.location.host)
  socket.on "new", (arr) ->
    all = all.concat(arr)
    i = 0
    l = arr.length

    while i < l
      entry = arr[i]
      if FILTER_MODE is 0
        filtered.push entry
      else if FILTER_MODE is 1
        if okay.length < MAX_LENGTH
          if !similar(okay, entry)
            okay.push entry
            okayLength++
          pending.push entry
        else
          j = 0

          while j < MAX_LENGTH
            okayVal = okay[j]
            if similar(okayVal, entry)
              okay.splice j, 1
              okay.push entry
              okayLength++
              if pending? and (okayLength <= REQUIRED_LENGTH or range(pending) < MIN_RANGE)
                pending.push okayVal
                filtered.push 0
              else if pending?
                filtered = filtered.slice(0, filtered.length-pending.length).concat(pending)
                pending = null
              if !pending?
                filtered.push entry
              # Entry is valid
              entry = null
              break
            j++
        if entry
          filtered.push 0
          okayLength = 0
          okay.shift()
          okay.push entry
          pending = []
      i++
    render(ctx1, filtered)
    render(ctx2, all)

render = (ctx, filtered) ->
  first = Math.max(0, filtered.length - CANVAS_WIDTH)
  draw = filtered.slice(first)
  mod = 20000
  ctx.clearRect 0, 0, CANVAS_WIDTH, CANVAS_HEIGHT
  i = 0
  l = draw.length

  height = CANVAS_HEIGHT * MIN_RANGE / mod
  ctx.fillRect 0, CANVAS_HEIGHT - height, CANVAS_WIDTH, 1
  while i < l
    height = CANVAS_HEIGHT * draw[i] / mod
    ctx.fillRect i, CANVAS_HEIGHT - height, 1, height
    i++
