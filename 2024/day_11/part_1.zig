const std = @import("std");

var AllocState = std.heap.GeneralPurposeAllocator(.{}){};
const GPA = AllocState.allocator();

const TESTING = false;

pub fn main() !void {
    defer _ = AllocState.deinit();

    var bags: [2]Bag = .{ undefined, Bag.init(GPA) };
    defer for (bags) |bag| bag.deinit();

    bags[0] = blk: {
        const path = if (TESTING) "test.txt" else "input.txt";
        const f = try std.fs.cwd().openFile(path, .{});
        defer f.close();
        break :blk try parseFile(f);
    };

    var cur = &bags[0];
    var dest = &bags[1];

    //try cur.append(125);
    //try cur.append(17);

    //std.log.debug("bag: {any}", .{cur.items});
    for (0..25) |_| {
        for (cur.items) |rock| try applyRule(rock, dest);
        std.mem.swap(*Bag, &cur, &dest);
        try dest.resize(0);
        //std.log.debug("bag: {any}", .{cur.items});
    }
    std.debug.print("{}\n", .{cur.items.len});
}

const Bag = std.ArrayList(usize);
fn applyRule(rock: usize, bag: *Bag) !void {
    //const logger = std.log.scoped(.rulez);
    if (rock == 0) {
        //logger.debug("0 -> 1", .{});
        try bag.append(1);
        return;
    }
    const log10 = std.math.log10(rock) + 1;
    //logger.info("log10({}) = {}", .{ rock, log10 });
    if (log10 & 1 == 0) {
        const scale = std.math.pow(usize, 10, log10 >> 1);
        const upper = rock / scale;
        const lower = rock - (upper * scale);
        //logger.debug("{} -> {} {}", .{ rock, upper, lower });
        try bag.append(upper);
        try bag.append(lower);
        return;
    }
    //logger.debug("{} -> {}", .{ rock, rock * 2024 });
    try bag.append(rock * 2024);
    return;
}

fn parseFile(file: std.fs.File) !Bag {
    const size = (try file.metadata()).size();
    const buff = try GPA.alloc(u8, size);
    defer GPA.free(buff);

    _ = try file.read(buff);

    var out = Bag.init(GPA);
    errdefer out.deinit();

    var walker = SSV{ .source = buff };

    while (walker.next()) |item| {
        try out.append(parseNum(item));
    }

    return out;
}

fn parseNum(ns: []const u8) usize {
    var acc: usize = 0;
    for (ns) |c| {
        if (!std.ascii.isDigit(c)) break;
        //std.log.debug("num {c}({})", .{ c, c });
        acc = acc * 10 + c - '0';
    }
    return acc;
}

const SSV = struct {
    source: []const u8,
    ind: usize = 0,

    fn consume(self: *@This()) ?u8 {
        if (self.ind >= self.source.len) return null;
        const ret = self.source[self.ind];
        self.ind += 1;
        return ret;
    }

    fn next(self: *@This()) ?[]const u8 {
        if (self.ind >= self.source.len) return null;
        const start = self.ind;
        const eoi = out: while (self.consume()) |c| {
            if (c != ' ') continue;
            break :out true;
        } else break :out false;
        const end = self.ind - @intFromBool(eoi);
        return self.source[start..end];
    }
};
