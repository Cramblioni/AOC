const std = @import("std");

var AllocState = std.heap.GeneralPurposeAllocator(.{}){};
const GPA = AllocState.allocator();

const TESTING = false;

pub fn main() !void {
    defer _ = AllocState.deinit();

    const content = blk: {
        const path = if (TESTING) "test.txt" else "input.txt";
        const f = try std.fs.cwd().openFile(path, .{});
        defer f.close();

        const buff = try GPA.alloc(u8, (try f.metadata()).size());
        errdefer GPA.free(buff);
        _ = try f.read(buff);
        break :blk buff;
    };
    var tests = std.ArrayList(Test).init(GPA);
    defer {
        for (tests.items) |thingy| GPA.free(thingy.args);
        tests.deinit();
    }
    {
        var lines = Lines{ .source = content };
        var buff = std.ArrayList(usize).init(GPA);
        while (lines.next()) |line| {
            const parts = splitTest(line);
            const goal = parseNum(parts.@"0");
            var ssv = SSV{ .source = parts.@"1" };
            while (ssv.next()) |cell| {
                try buff.append(parseNum(cell));
            }
            const thing = Test{
                .goal = goal,
                .args = try buff.toOwnedSlice(),
            };
            try tests.append(thing);
        }
    }
    var score: usize = 0;
    for (tests.items) |thing| {
        if (!try isTestPossible(thing)) continue;
        //std.log.debug("{}: {any}", .{ thing.goal, thing.args });
        score += thing.goal;
    }
    std.debug.print("{}\n", .{score});
    GPA.free(content);
}

const Test = struct {
    goal: usize,
    args: []const usize,
};
const Oper = enum {
    Add,
    Mul,
    Con,
    fn apply(self: Oper, x: usize, y: usize) usize {
        return switch (self) {
            .Add => x + y,
            .Mul => x * y,
            .Con => x * scoogle(y) + y,
        };
    }
};

inline fn pow10(y: u8) usize {
    var p: usize = 1;
    inline for (0..y) |_| p *= 10;
    return p;
}
fn scoogle(x: usize) usize {
    inline for (0..22) |i| {
        const p = pow10(i);
        if (x < p) return p;
    }
    std.log.scoped(.scoogle).debug("big number: `{}`", .{x});
    unreachable;
}

fn eval(args: []const usize, opers: []const Oper) usize {
    var accum = args[0];
    for (opers, args[1..]) |oper, arg| {
        accum = oper.apply(accum, arg);
    }
    return accum;
}

fn isTestPossible(tst: Test) !bool {
    const opers = try GPA.alloc(Oper, tst.args.len - 1);
    defer GPA.free(opers);
    return fillOpersThenEval(tst, opers, opers);
}
fn fillOpersThenEval(tst: Test, opers: []const Oper, targ: []Oper) bool {
    if (targ.len == 0) {
        const val = eval(tst.args, opers);
        return val == tst.goal;
    }
    targ[0] = .Con;
    if (fillOpersThenEval(tst, opers, targ[1..])) return true;
    targ[0] = .Add;
    if (fillOpersThenEval(tst, opers, targ[1..])) return true;
    targ[0] = .Mul;
    return fillOpersThenEval(tst, opers, targ[1..]);
}

const SSV = struct {
    source: []const u8,
    ind: usize = 0,
    fn consume(self: *SSV) ?u8 {
        if (self.ind >= self.source.len) return null;
        const val = self.source[self.ind];
        self.ind += 1;
        return val;
    }
    fn next(self: *SSV) ?[]const u8 {
        if (self.ind >= self.source.len) return null;
        const start = self.ind;
        const noeol = blk: while (true) {
            if (self.consume()) |x| {
                if (x == ' ') break :blk true;
            } else break :blk false;
        };
        const end = self.ind - @intFromBool(noeol);
        return self.source[start..end];
    }
};
const Lines = struct {
    source: []const u8,
    ind: usize = 0,
    fn consume(self: *Lines) ?u8 {
        if (self.ind >= self.source.len) return null;
        const val = self.source[self.ind];
        self.ind += 1;
        return val;
    }
    fn next(self: *Lines) ?[]const u8 {
        if (self.ind >= self.source.len) return null;
        const start = self.ind;
        const noeol = blk: while (true) {
            if (self.consume()) |x| {
                if (x == '\n') break :blk true;
            } else break :blk false;
        };
        const end = self.ind - @intFromBool(noeol);
        return self.source[start..end];
    }
};

fn splitTest(x: []const u8) struct { []const u8, []const u8 } {
    for (0..x.len) |i| {
        if (x[i] == ':') return .{
            x[0..i],
            x[i + 2 ..],
        };
    }
    unreachable;
}

fn parseNum(xs: []const u8) usize {
    var accum: usize = 0;
    for (xs) |x| {
        accum = (accum * 10) + (x - '0');
    }
    return accum;
}
