import sys
from typing import Optional
from functools import partial

class Node:
    __slots__ = ("sons","pos", "height")
    sons: list["Node"]
    pos: tuple[int,int]
    height: int
    def __init__(self, sons: list["Node"]) -> None:
        self.sons = sons
        self.pos = (-1, -1)
    def __str_i__(self,excl) -> str:
        if self in excl: return "..."
        return f"<{self.pos}"\
        f"[{', '.join(map(partial(Node.__str_i__, excl=[self, *excl]), self.sons))}]>"

    def __str__(self):
        return self.__str_i__([])

    __repr__ = __str__

def parse(text: str) -> tuple[list[list[tuple[Node, int]]],Node, Node]:
    # create a grid of nodes and a heightmap.
    # then using that to create a graph that only has
    # allowed paths.
    # Also keeping a reference to start and end nodes because simplicity
    pal: str = "abcdefghijklmnopqrstuvwxyz"
    grid: list[list[tuple[Node, int]]] = []

    start: Node
    end: Node

    for y, line in enumerate(text.splitlines()):
        row = []
        for x, c in enumerate(line):
            tnode = Node([])
            tnode.pos = (x, y)
            if   c == 'S': start, c = tnode, 'a'
            elif c == 'E': end, c   = tnode, 'z'
            x = pal.index(c)
            tnode.height = x
            row.append((tnode, x))
        grid.append(row)

    # doing this before i fuck something up later
    assert "start" in locals()
    assert "end" in locals()
    return grid, start, end

def link(grid, start, end) -> tuple[Node, Node]:
    for y, row in enumerate(grid, 0):
        #print("LINK/ROW::", row)
        for x, (tnode, height) in enumerate(row, 0):
            cells: list[tuple[Node, int]] = []
            if y > 0: cells.append(grid[y - 1][x])
            if x > 0: cells.append(grid[y][x - 1])
            if y < len(grid) - 1: cells.append(grid[y + 1][x])
            if x < len(row) - 1: cells.append(grid[y][x + 1])
            for (cell, cht) in cells:
                if cht <= height + 1: tnode.sons.append(cell)
            #print(f"[{x}, {y}]",len(cells))
    return start, end

def find(start: Node, end: Node) -> list[list[Node]]:
    # tmp {path/excl, node}
    tmp = [([], start)]
    while len(tmp) > 0:
        excl, front = tmp.pop()
        path = [*excl, front]
        #print("TESTING::", [i.pos for i in path], end="...")
        if front is end:
            yield path
            #print("hit end")
            continue
        v00 = list(filter(lambda x: x not in excl, front.sons))
        if len(v00) == 0:
            #print("Dead")
            continue
        tmp.extend(map(lambda x: (path, x), v00))
        #print("unfinished")

def acc(f, node):
    tmp, prev = [node], []
    while len(tmp) > 0:
        n = tmp.pop()
        if n in prev: continue
        prev.append(n)
        yield f(n)
        tmp.extend(n.sons)


if __name__ == "__main__":
    pres = parse(sys.stdin.read())
    #print(*pres[0], sep="\n")
    #print("START::", pres[1])
    #print("END::  ", pres[2])
    #print("LINKING")
    start, end = link(*pres)
    assert end is pres[2]
    #print("START::",str(start.pos))
    #print("END ACCESSIBLE::", any(acc(lambda x: x is end, start)))
    # debug stuff
    # import PIL
    # import PIL.Image as pImg
    # import PIL.ImageDraw as pDraw
    # with pImg.new("RGB", (len(pres[0][0]), len(pres[0]))) as img:
    #     cur = pDraw.Draw(img)

        # def forNode(node : Node):
        #     x, y = node.pos
        #     #print("Drawing", x, y)
        #     if node is end or node is pres[2]:
        #         cur.point((x, y), (255,0,0))
        #         return
        #     cur.point((x, y), (node.height * 10, 100, 100))

        #for _ in acc(forNode, start): pass
    paths = []
    for spath in find(start, end):
        print(*map(lambda x: x.pos, spath))
        paths.append(spath[1:])
    path = min(paths, key=len)
        #for i in path:
        #    cur.point(i.pos)
        #img.save("hopper.ppm","ppm")
    print(len(path))
