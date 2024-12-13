const std = @import("std");
var AllocState = std.heap.GeneralPurposeAllocator(.{}){};
const GPA = AllocState.allocator();

const TESTING = false;

pub fn main() !void {
    defer _ = AllocState.deinit();

    const machines = blk: {
        const path = if (TESTING) "test.txt" else "input.txt";
        const f = try std.fs.cwd().openFile(path, .{});
        const buff = try GPA.alloc(u8, (try f.metadata()).size());
        defer GPA.free(buff);
        _ = try f.read(buff);
        f.close();

        var bag = std.ArrayList(Machine).init(GPA);
        var itr = Parser{ .source = buff };
        while (itr.next()) |m| try bag.append(m);
        break :blk try bag.toOwnedSlice();
    };
    defer GPA.free(machines);

    var score: usize = 0;
    for (machines) |m| {
        std.log.debug("a: {}, b: {}, prize: {}", .{ m.a, m.b, m.prize });
        score += m.calcCost() orelse 0;
    }
    std.debug.print("{}\n", .{score});
}

const V2 = struct {
    x: u16,
    y: u16,

    fn add(a: V2, b: V2) V2 {
        return .{ .x = a.x + b.x, .y = a.y + b.y };
    }
    fn scale(a: V2, b: u16) V2 {
        return .{ .x = a.x * b, .y = a.y * b };
    }
};
const Machine = struct {
    a: V2,
    b: V2,
    prize: V2,

    fn calcCost(self: Machine) ?usize {
        const MAXINT = 0xFFFF_FFFF_FFFF_FFFF;
        var minCost: usize = MAXINT;
        for (0..100) |nb| for (0..100) |na| {
            const r = self.a.scale(@intCast(na)).add(self.b.scale(@intCast(nb)));
            if (!std.meta.eql(r, self.prize)) continue;
            minCost = @min(minCost, nb + na * 3);
        };
        if (minCost == MAXINT) return null;
        return minCost;
    }
};

const Parser = struct {
    source: []const u8,
    ind: usize = 0,
    fn next(self: *Parser) ?Machine {
        if (self.ind >= self.source.len) return null;
        const r = self.parseMachine();
        _ = self.consume();
        return r;
    }

    fn consume(self: *Parser) u8 {
        if (self.ind >= self.source.len) return 0;
        const r = self.source[self.ind];
        self.ind += 1;
        return r;
    }
    fn skip(self: *Parser, d: usize) void {
        self.ind += d;
    }
    fn parseNum(self: *Parser) u16 {
        var acc: u16 = 0;
        while (self.ind < self.source.len) {
            const char = self.consume();
            if (!std.ascii.isDigit(char)) break;
            acc = acc * 10 + (char - '0');
        }
        return acc;
    }
    fn parseV2(self: *Parser) V2 {
        // pulling `X+`
        self.skip(2);
        const x = self.parseNum();
        // pulling ` Y+`
        self.skip(3);
        const y = self.parseNum();
        return .{ .x = x, .y = y };
    }
    fn parseMachine(self: *Parser) Machine {
        const a = self.parseButton();
        const b = self.parseButton();
        const prize = self.parsePrize();
        return .{ .a = a, .b = b, .prize = prize };
    }
    fn parseButton(self: *Parser) V2 {
        self.skip(10);
        return self.parseV2();
    }
    fn parsePrize(self: *Parser) V2 {
        self.skip(7);
        return self.parseV2();
    }
};
