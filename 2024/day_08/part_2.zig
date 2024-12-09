const std = @import("std");

var AllocState = std.heap.GeneralPurposeAllocator(.{}){};
const GPA = AllocState.allocator();

const TESTING = false;
const SIZE: usize = if (TESTING) 12 else 50;

pub fn main() !void {
    defer _ = AllocState.deinit();

    const base = try Grid.new();
    defer GPA.destroy(base);
    {
        const path = if (TESTING) "test.txt" else "input.txt";
        const f = try std.fs.cwd().openFile(path, .{});
        defer f.close();
        for (0..SIZE) |r| {
            if (r + 1 >= SIZE)
                _ = try f.read(base.inner[r * SIZE .. (r + 1) * SIZE])
            else
                _ = try f.read(base.inner[r * SIZE .. (r + 1) * SIZE + 1]);
        }
    }
    var signals = std.AutoHashMap(u8, std.ArrayList(Pos)).init(GPA);
    defer {
        var itr = signals.valueIterator();
        while (itr.next()) |bucket| bucket.deinit();
        signals.deinit();
    }
    for (0..SIZE) |r| for (0..SIZE) |c| {
        const got = base.get(@intCast(r), @intCast(c)).?;
        if (got == '.') continue;
        const entry = try signals.getOrPut(got);
        if (!entry.found_existing)
            entry.value_ptr.* = std.ArrayList(Pos).init(GPA);
        try entry.value_ptr.append(.{ .r = @intCast(r), .c = @intCast(c) });
    };

    var itr = signals.valueIterator();
    while (itr.next()) |signal| {
        var pairer = Pairer{ .source = signal.items };
        while (pairer.next()) |pair| {
            const a = pair.@"0";
            const b = pair.@"1";
            const d = a.sub(b);
            var n = a.add(d);
            base.put(n.r, n.c, Grid.ANTINODE);
            while (n.inBounds()) {
                n = n.add(d);
                base.put(n.r, n.c, Grid.ANTINODE);
            }
        }
    }

    var count: usize = 0;
    for (base.inner) |c| count += @intFromBool(c != Grid.EMPTY);
    std.debug.print("{}\n", .{count});
}

const Pos = struct {
    r: i16,
    c: i16,
    fn add(a: Pos, b: Pos) Pos {
        return .{ .r = a.r + b.r, .c = a.c + b.c };
    }
    fn sub(a: Pos, b: Pos) Pos {
        return .{ .r = a.r - b.r, .c = a.c - b.c };
    }
    fn inBounds(p: Pos) bool {
        return p.r >= 0 and p.r < SIZE and p.c >= 0 and p.c < SIZE;
    }
};
const Grid = struct {
    inner: [SIZE * SIZE]u8,

    const EMPTY: u8 = '.';
    const ANTINODE: u8 = '#';
    fn new() !*Grid {
        const me = try GPA.create(Grid);
        return me;
    }
    fn get(self: *Grid, r: i16, c: i16) ?u8 {
        if (r < 0 or c < 0) return null;
        if (r >= SIZE or c >= SIZE) return null;
        return self.inner[@as(usize, @intCast(r)) * SIZE + @as(usize, @intCast(c))];
    }
    fn put(self: *Grid, r: i16, c: i16, v: u8) void {
        if (r < 0 or c < 0) return;
        if (r >= SIZE or c >= SIZE) return;
        const cell = &self.inner[@as(usize, @intCast(r)) * SIZE + @as(usize, @intCast(c))];
        //if (cell.* != EMPTY) return;
        cell.* = v;
    }
};

const Pairer = struct {
    source: []Pos,
    a: usize = 0,
    b: usize = 0,

    fn next(self: *Pairer) ?struct { Pos, Pos } {
        if (self.b >= self.source.len) {
            self.a += 1;
            self.b = 0;
        }
        if (self.a >= self.source.len) return null;
        const a = self.source[self.a];
        const b = self.source[self.b];
        self.b += 1;
        if (std.meta.eql(a, b)) return self.next();
        return .{ a, b };
    }
};
