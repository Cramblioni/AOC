import os, strformat

func schlock*[T](dest: var seq[T], src: seq[T]) =
  for i in src: dest.add i

type
  Point* = object
    x, y: int

  Node* = ref object
    pos: Point
    sons: seq[Node]

  parseOut* = object
    start: Node
    endp: Node

  Path* = seq[Node]

func `$`*(x: Point): string = fmt"<{x.x}, {x.y}>"
func `$`*(x: Node): string = (if x == nil: "<nil>" else: $x.pos)

proc parse(file: File): parseOut {. raises: [IOError, ValueError] .} =
  type Cell = object
    node: Node
    height: int
  var
    start: Node = nil
    endp: Node = nil
  var grid : seq[seq[Cell]] = newSeqOfCap[seq[Cell]](32)
  block Parse:
    const lookup = "abcdefghijklmnopqrstuvwxyz"
    var y = 0
    for line in file.lines:
      var tmp = newSeqOfCap[Cell](32)
      for x, c in line:
        let cn = Node(sons:newSeqOfCap[Node](4), pos:Point(x: x, y: y))
        let lc = lookup.find(case c
        of 'S': start = cn; 'a'
        of 'E': endp  = cn; 'z'
        else: c)
        tmp.add(Cell(node: cn, height: lc))
      grid.add tmp
      echo "added row of len ", tmp.len
      inc y
  assert start != nil
  assert endp  != nil
  block Link:
    echo "linking"
    for y, row in grid: # row: seq[Cell]
      for x, cell in row:
        assert cell.node != nil
        var cells = newSeqOfCap[Cell](4)
        if y > 0:            cells.add(grid[y - 1][x])
        if y < grid.len - 1: cells.add(grid[y + 1][x])
        if x > 0:            cells.add(grid[y][x - 1])
        if x > row.len - 1:  cells.add(grid[y][x + 1])
        echo "cell ", cell.node, " linked with ", cells.len, " other cells"
        for ncell in cells:
          if ncell.height <= cell.height + 1: cell.node.sons.add ncell.node
  return parseOut(start: start, endp: endp)

func sqdist(a, b: Point): int =
  let
    x = (a.x - b.x)
    y = (a.y - b.y)
  x*x + y*y

func getNearest(opts: var seq[Path], targ: Node): Path =
  var
    mind = -1
    mdist = int.high
  for i, x in opts:
    let cd = sqdist(x[^1].pos, targ.pos)
    if cd < mdist:
      mdist = cd
      mind = i
  assert mind > -1
  if mind == opts.len - 1:
    return opts.pop()
  let tmp = opts[mind]
  opts[mind] = opts[^1]
  discard opts.pop()
  return tmp


func find(root: Node, targ: Node): seq[Path] =
  var pool = newSeqOfCap[Path](32)
  pool.add(@[root])
  result = newSeqOfCap[Path](32)
  while pool.len > 0:
    let cur {. used .} = getNearest(pool, targ)

proc main(argv: seq[string]) =
  let graph = parse(stdin)
  # debugging the produced graph [as just an edge table]
  var stack = newSeq[Node]()
  var prev  = newSeq[Node]()
  stack.add(graph.start)
  while stack.len > 0:
    let cur = stack.pop()
    if cur in prev: continue
    prev.add cur
    if cur == nil:
      echo "hit nil"
      continue
    echo cur
    for i in cur.sons:
      stack.add i
      echo "\t", i

when isMainModule:
  main(commandLineParams())