import nimsvg
import nimsvg/timeline
import nimsvg/styles
import os
import strformat
import math
import lenientops

let style = defaultStyle()
let warnColor = "#de133f"
let highlighColor = "#ee741d"

# General geometry
let w = 700
let h = 250
let rectW = 30.0

let (insertX, insertY) = (w.float / 2.0, 30.0)

let topY = 120.0
let botY = 200.0


proc drawNumber(xy: (float, float), val: string, ghost: bool = false, opacity = 1.0): Nodes =
  let (stroke, fill) =
    if ghost:
      ("#DDDDDD", "#DDDDDD")
    else:
      ("#111", "#444")

  let (x, y) = xy
  let style = style.fillOpacity(opacity).strokeOpacity(opacity)
  buildSvg:
    embed style.stroke("#333").fill("#FBFBFF").rx(4).rectCentered(x, y, rectW, rectW)
    embed style.fontSize(16).fill(fill).stroke(stroke).text(x, y, val)


proc drawBinarySearchVis(f: TimelineFrame, xs: seq[float], y: float, frame: string, iHighlight: int): Nodes =
  let middle = xs.sum() / xs.len()
  buildSvg:
    let opacity = f.calc({
      &"{frame}[-0.1 s]": 0.0,
      &"{frame} ease": 1.0,
      &"{frame}[end] ease": 0.0,
    })
    let offset = f.calc({
      &"{frame}[-0.1 s]": 10.0,
      &"{frame}[end] linear": 0.0,
    })
    let r = f.calc({
      &"{frame}[-0.1 s]": rectW / 2 * 1.2,
      &"{frame}[end] ease": rectW / 2 * 1.0,
    })
    let circleStyle = style.fill("none").stroke("#445").strokeOpacity(opacity).strokeWidth(2.0)
    for i, x in xs.pairs:
      if i != iHighlight:
        embed circleStyle.circle(x=x, y=y, r=r)
      else:
        embed circleStyle.stroke(highlighColor).circle(x=x, y=y, r=r)
    embed style
      .fillOpacity(opacity)
      .fontSize(10)
      .text(middle, y - 28 - offset, "binary search")


proc drawLine(p1: (float, float), p2: (float, float), opacity = 1.0): Nodes =
  style
    .stroke("#888")
    .strokeOpacity(opacity)
    .line(p1[0], p1[1] + rectW / 2, p2[0], p2[1] - rectW / 2)


proc drawInsertAnimation(f: TimelineFrame): Nodes =
  let offset = f.calc({
    "f1.init": 50.0,
    "f1.init[end] outcubic": 0.0,
    "f2.init": 50.0,
    "f2.init[end] outcubic": 0.0,
  })
  let opacity = f.calc({
    "f1.init": 0.0,
    "f1.init[end] outcubic": 1.0,
    "f2.init outcubic": 0.0,
    "f2.init[end] outcubic": 1.0,
    "f2.insert[end] outcubic": 0.0,
  })
  let x = w / 2.0 - 30 - offset
  style
    .withTextAlignRight()
    .fillOpacity(opacity)
    .text(x=x, y=insertY, "Insert:")


proc drawMaxLeafCapacity(f: TimelineFrame): Nodes =
  buildSvg:
    embed style.withTextAlignLeft().text(x=30, y=insertY, "Max leaf capacity: 4")
    let maxLeafWarnOpacity = f.calc({
      "f2.split[-0.1s]": 0.0,
      "f2.split linear": 1.0,
      "f2.split[end] linear": 0.0,
    })
    let styleRed = style.fill(warnColor).stroke(warnColor).strokeOpacity(maxLeafWarnOpacity).fillOpacity(maxLeafWarnOpacity)
    embed styleRed.fillOpacity(maxLeafWarnOpacity*0.01).rx(8).rect(20, insertY-20, 165, 40)
    embed styleRed.withTextAlignCenter().noStroke().fontSize(10).text(20.0 + 165.0/2.0, insertY+30, "split leaf")


let durHighlight = 1.0
let durBS = 1.0
let durInsert = 1.0
let frames = frames([
  ("f1.init", durHighlight),
  ("f1.bs1", durBS),
  ("f1.bs2", durBS),
  ("f1.insert", durInsert),

  ("f2.init", durHighlight),
  ("f2.bs1", durBS),
  ("f2.split", 2.0),
  ("f2.bs2", durBS),
  ("f2.insert", durInsert),
])

let settings = animSettings(
  filenameBase="examples" / sourceBaseName(),
  gifFrameTime=2,
  renderGif=false,
)

settings.buildAnimationTimeline(frames) do (f: TimelineFrame) -> Nodes:

  let numTopElements = f.calc({
    "f2.split": 4.0,
    "f2.split[end] ease": 5.0,
  })

  proc topX(i: int): float =
    let left = w.float / 2.0 - ((numTopElements - 1) * rectW / 2.0)
    left + i * rectW

  proc botX(i, j: int): float =
    let margin = 30
    let totalW = w - margin * 2
    let blockW = totalW / (numTopElements)
    let base = margin + (i * blockW) + blockW/2
    base - (1.5 * rectW) + j * rectW

  let pos02 = {"f1.init": (botX(0, 0), botY)}
  let pos03 = {"f1.insert": (insertX, insertY), "f1.insert[end] ease": (botX(0, 1), botY)}
  let pos05 = {"f1.insert": (botX(0, 1), botY), "f1.insert[end] ease": (botX(0, 2), botY)}

  let pos08 = {"f1.init": (botX(1, 0), botY)}
  let pos11 = {"f1.init": (botX(1, 1), botY)}
  let pos13 = {"f2.split": (botX(1, 2), botY), "f2.split[end] ease": (botX(2, 0), botY)}
  let pos15 = {"f2.insert": (insertX, insertY), "f2.insert[end] ease": (botX(2, 1), botY)}
  let pos16 = {"f2.split": (botX(1, 3), botY), "f2.split[end] ease": (botX(2, 1), botY), "f2.insert[end] ease": (botX(2, 2), botY)}

  let pos19 = {"f2.split": (botX(2, 0), botY), "f2.split[end] ease": (botX(3, 0), botY)}
  let pos22 = {"f2.split": (botX(2, 1), botY), "f2.split[end] ease": (botX(3, 1), botY)}

  let pos28 = {"f2.split": (botX(3, 0), botY), "f2.split[end] ease": (botX(4, 0), botY)}
  let pos32 = {"f2.split": (botX(3, 1), botY), "f2.split[end] ease": (botX(4, 1), botY)}
  let pos38 = {"f2.split": (botX(3, 2), botY), "f2.split[end] ease": (botX(4, 2), botY)}

  let posGhost02 = {"f2.split": (topX(0), topY)}
  let posGhost08 = {"f2.split": (topX(1), topY)}
  let posGhost13 = {"f2.split[end]": (topX(2), topY)}
  let posGhost19 = {"f2.split": (topX(2), topY), "f2.split[end] ease": (topX(3), topY)}
  let posGhost28 = {"f2.split": (topX(3), topY), "f2.split[end] ease": (topX(4), topY)}

  buildSvg:
    svg(width=w, height=h, style="border: 1px solid #EFEFEF;"):
      embed style.fontSize(10).withTextAlignRight().text(
        x=w-8.0, y=h-12.0, &"created with NimSVG (frame: {f.i:03d}, time: {f.t:.2f})"
      )

      embed f.drawInsertAnimation()
      embed f.drawMaxLeafCapacity()

      # draw line connections
      let ghost13Opacity = f.calc({"f2.split[50%]": 0.0, "f2.split[100%] ease": 1.0})
      embed drawLine(f.calc(posGhost02), f.calc(pos02))
      embed drawLine(f.calc(posGhost08), f.calc(pos08))
      embed drawLine(f.calc(posGhost13), f.calc(pos13), opacity=ghost13Opacity)
      embed drawLine(f.calc(posGhost19), f.calc(pos19))
      embed drawLine(f.calc(posGhost28), f.calc(pos28))

      # draw top level numbers
      embed drawNumber(f.calc(posGhost02), "2", ghost=true)
      embed drawNumber(f.calc(posGhost08), "8", ghost=true)
      embed drawNumber(f.calc(posGhost13), "13", ghost=true, opacity=ghost13Opacity)
      embed drawNumber(f.calc(posGhost19), "19", ghost=true)
      embed drawNumber(f.calc(posGhost28), "28", ghost=true)

      # draw leaf level numbers
      embed drawNumber(f.calc(pos02), "2")
      embed drawNumber(f.calc(pos05), "5")

      embed drawNumber(f.calc(pos08), "8")
      embed drawNumber(f.calc(pos11), "11")
      embed drawNumber(f.calc(pos13), "13")
      embed drawNumber(f.calc(pos16), "16")

      embed drawNumber(f.calc(pos19), "19")
      embed drawNumber(f.calc(pos22), "22")

      embed drawNumber(f.calc(pos28), "28")
      embed drawNumber(f.calc(pos32), "32")
      embed drawNumber(f.calc(pos38), "38")

      # inserted numbers
      embed drawNumber(f.calc(pos03), "3", opacity=f.calc({
        "f1.init": 0.0,
        "f1.init[end] linear": 1.0,
      }))
      embed drawNumber(f.calc(pos15), "15", opacity=f.calc({
        "f2.init": 0.0,
        "f2.init[end] linear": 1.0,
      }))

      # binary search highlighting
      embed f.drawBinarySearchVis(
        xs= @[topX(0), topX(1), topX(2), topX(3)],
        y=topY,
        frame="f1.bs1",
        iHighlight=0,
      )
      embed f.drawBinarySearchVis(
        xs= @[botX(0, 0), botX(0, 1)],
        y=botY,
        frame="f1.bs2",
        iHighlight=0,
      )
      embed f.drawBinarySearchVis(
        xs= @[topX(0), topX(1), topX(2), topX(3)],
        y=topY,
        frame="f2.bs1",
        iHighlight=1,
      )
      embed f.drawBinarySearchVis(
        xs= @[botX(2, 0), botX(2, 1)],
        y=botY,
        frame="f2.bs2",
        iHighlight=0,
      )
