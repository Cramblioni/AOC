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
        var nums: [10]u8 = undefined; // I saw up to 8, but round up (:
        var puller = Puller{ .source = line };
        var n_nums: u8 = 0;
        for (&nums) |*num| {
            num.* = intToStr(puller.pullNum());
            n_nums += 1;
            if (puller.consume() != ' ') break;
        }
        if (!isSafe(nums[0..n_nums])) {
            //std.log.debug("Unsafe: {any}", .{nums[0..n_nums]});
            continue :outer;
        }
        count += 1;
        //std.log.debug("Safe:   {any}", .{nums[0..n_nums]});
    }
    std.debug.print("{}\n", .{count});
}

fn isSafe(xs: []u8) bool {
    const all_inc = allInc(xs);
    const all_dec = allDec(xs);

    for (xs[0 .. xs.len - 1], xs[1..]) |a, b|
        if (!validDelta(a, b)) return false;
    return all_inc != all_dec;
}

fn allInc(xs: []u8) bool {
    for (xs[0 .. xs.len - 1], xs[1..]) |a, b|
        if (a >= b) return false;
    return true;
}
fn allDec(xs: []u8) bool {
    for (xs[0 .. xs.len - 1], xs[1..]) |a, b|
        if (a <= b) return false;
    return true;
}

fn validDelta(a: u8, b: u8) bool {
    const dif: u8 = if (a > b) (a - b) else (b - a);
    return dif > 0 and dif <= 3;
}

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
