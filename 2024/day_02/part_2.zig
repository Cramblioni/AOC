const std = @import("std");

var AllocState = std.heap.GeneralPurposeAllocator(.{}){};
const GPA = AllocState.allocator();

const TESTING = false;

pub fn main() !void {
    defer _ = AllocState.deinit();
    const file = if (TESTING)
        try std.fs.cwd().openFile("test.txt", .{})
    else
        try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var reader = file.reader();

    var buff: [64]u8 = undefined;
    var count: usize = 0;
    outer: while (try reader.readUntilDelimiterOrEof(&buff, '\n')) |line| {
        //std.log.debug("{s}", .{line});
        //std.debug.print("\n", .{});
        var nums: [10]u8 = undefined; // I saw up to 8, but round up (:
        var puller = Puller{ .source = line };
        var n_nums: u8 = 0;
        for (&nums) |*num| {
            num.* = intToStr(puller.pullNum());
            n_nums += 1;
            if (puller.consume() != ' ') break;
        }
        if (!try isSafe(nums[0..n_nums])) {
            //std.log.debug("Unsafe: {any}", .{nums[0..n_nums]});
            continue :outer;
        }
        count += 1;
        //std.log.debug("Safe:   {any}", .{nums[0..n_nums]});
    }
    std.debug.print("{}\n", .{count});
}

fn isSafe(xs: []const u8) !bool {
    if (isWholeSafe(xs)) return true;

    const buff = try GPA.alloc(u8, xs.len - 1);
    defer GPA.free(buff);
    for (0..xs.len) |i| {
        @memcpy(buff[0..i], xs[0..i]);
        @memcpy(buff[i..], xs[i + 1 ..]);
        if (isWholeSafe(buff)) return true;
    }
    return false;
}

fn isWholeSafe(xs: []const u8) bool {
    const trend = getTrend(xs);
    var marcher = DeltaMarcher{ .source = xs };
    while (marcher.read()) |step| {
        //std.log.debug("{},{}", .{ marcher.back, marcher.front });
        if (step != trend) {
            return false;
        }
        const val = switch (step) {
            .Rising => |x| x,
            .Falling => |x| x,
        };
        if (val == 0 or val > 3) {
            return false;
        }
        marcher.stepBack();
        marcher.stepFront();
    }
    return true;
}
const Trend = enum { Rising, Falling };
fn getTrend(xs: []const u8) Trend {
    var rise: u8 = 0;
    var fall: u8 = 0;
    for (xs[0 .. xs.len - 1], xs[1..]) |a, b| {
        if (a > b) {
            fall += 1;
        } else {
            rise += 1;
        }
    }
    if (rise > fall) {
        return .Rising;
    } else {
        return .Falling;
    }
}
fn allValidDeltas(xs: []const u8) bool {
    for (xs[0 .. xs.len - 1], xs[1..]) |a, b|
        if (!validDelta(a, b)) return false;
    return true;
}
fn validDelta(a: u8, b: u8) bool {
    const dif: u8 = if (a > b) (a - b) else (b - a);
    return dif > 0 and dif <= 3;
}

const Delta = union(Trend) { Rising: u8, Falling: u8 };
const DeltaMarcher = struct {
    source: []const u8,
    front: u8 = 1,
    back: u8 = 0,

    fn read(self: *DeltaMarcher) ?Delta {
        if (self.front >= self.source.len) return null;
        const a = self.source[self.back];
        const b = self.source[self.front];
        if (a > b) {
            return .{ .Falling = a - b };
        } else {
            return .{ .Rising = b - a };
        }
    }
    fn stepFront(self: *DeltaMarcher) void {
        self.front += 1;
    }
    fn stepBack(self: *DeltaMarcher) void {
        self.back = self.front;
    }
};

const Puller = struct {
    source: []u8,
    ind: u8 = 0,
    fn peek(self: *const Puller) u8 {
        if (self.ind == self.source.len) return 0;
        return self.source[self.ind]; // May crash, We don't care.
    }
    fn consume(self: *Puller) u8 {
        const val = self.peek();
        self.ind += 1;
        return val;
    }

    // borrows from self.source
    fn pullNum(self: *Puller) []u8 {
        const start = self.ind;
        _ = self.consume();
        if (std.ascii.isDigit(self.peek())) _ = self.consume();
        return self.source[start..self.ind];
    }
};

fn intToStr(str: []u8) u8 {
    var out: u8 = 0;
    for (str) |char| {
        out = out * 10 + (char - '0');
    }
    return out;
}
