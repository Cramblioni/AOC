const std = @import("std");

const TESTING = true;

var AllocState = std.heap.GeneralPurposeAllocator(.{}){};
const GPA = AllocState.allocator();

const RuleSet = std.AutoHashMap(u8, std.ArrayList(u8));

pub fn main() !void {
    defer _ = AllocState.deinit();

    const f = try if (TESTING)
        std.fs.cwd().openFile("test.txt", .{})
    else
        std.fs.cwd().openFile("input.txt", .{});

    const reader = f.reader().any();

    // Reading ordering
    var mapping = RuleSet.init(GPA);
    defer {
        var itr = mapping.valueIterator();
        while (itr.next()) |val| {
            val.deinit();
        }
        mapping.deinit();
    }
    {
        var buff: [6]u8 = undefined;
        while (true) {
            const sub_buff = (try reader.readUntilDelimiterOrEof(&buff, '\n')) orelse &.{};
            if (sub_buff.len == 0) break;
            var a: u8 = 0;
            a += (sub_buff[0] - '0') * 10;
            a += (sub_buff[1] - '0') * 1;

            var b: u8 = 0;
            b += (sub_buff[3] - '0') * 10;
            b += (sub_buff[4] - '0') * 1;

            const entry = try mapping.getOrPut(b);
            if (!entry.found_existing) {
                entry.value_ptr.* = std.ArrayList(u8).init(GPA);
            }
            try entry.value_ptr.append(a);
        }
        // var itr = mapping.iterator();
        // while (itr.next()) |kv| {
        //     std.log.debug("{}: {any}", .{ kv.key_ptr.*, kv.value_ptr.items });
        // }
    }
    // Reading updates
    var updates = std.ArrayList(std.ArrayList(u8)).init(GPA);
    defer {
        for (updates.items) |update| update.deinit();
        updates.deinit();
    }
    {
        var buff: [1024]u8 = undefined;
        while (true) {
            const sub_buff = try reader.readUntilDelimiterOrEof(&buff, '\n') orelse {
                break;
            };
            if (sub_buff.len == 0) break;
            var temp = std.ArrayList(u8).init(GPA);
            errdefer temp.deinit();
            var csv = CSV{ .source = sub_buff };
            while (csv.next()) |cell| {
                const val = (cell[0] - '0') * 10 + cell[1] - '0';
                try temp.append(val);
            }
            try updates.append(temp);
        }
        // for (updates.items) |update| std.log.debug("{any}", .{update.items});
    }
    // finishing reading :)
    f.close();

    // validating lines
    var score: u32 = 0;
    for (updates.items) |update| {
        if (validateUpdate(&mapping, update.items)) continue;
        try fix(&mapping, update.items);
        score += update.items[update.items.len >> 1];
    }
    std.debug.print("{}\n", .{score});
}

const CSV = struct {
    source: []const u8,
    ind: usize = 0,

    fn consume(self: *CSV) ?u8 {
        if (self.ind >= self.source.len) {
            return null;
        }
        const ret = self.source[self.ind];
        self.ind += 1;
        return ret;
    }
    fn next(self: *CSV) ?[]const u8 {
        if (self.ind >= self.source.len) return null;
        const start = self.ind;
        const eol = blk: while (true) {
            if (self.consume()) |x| switch (x) {
                ',' => break :blk false,
                else => continue,
            } else break :blk true;
        };
        const end = self.ind;
        return self.source[start .. end - @intFromBool(!eol)];
    }
};

fn validateUpdate(rules: *RuleSet, update: []const u8) bool {
    for (0.., update) |i, val| {
        const rule = if (rules.get(val)) |x| x else continue;
        for (rule.items) |exclude| {
            if (!contains(update[i..], exclude)) continue;
            return false;
        }
    }
    return true;
}

fn contains(xs: []const u8, v: u8) bool {
    for (xs) |x| if (x == v) return true;
    return false;
}

fn fix(rules: *const RuleSet, update: []u8) !void {
    var rewriter = Rewriter{
        .rules = rules,
        .bag = try std.ArrayList(u8).initCapacity(GPA, update.len),
        .buff = update,
    };
    for (update) |cell| {
        rewriter.push(cell);
    }
    while (rewriter.bag.items.len > 0) {
        rewriter.handleStackDrain();
    }
}

const Rewriter = struct {
    rules: *const RuleSet,
    bag: std.ArrayList(u8), // Like a free access stack
    buff: []u8,
    write: usize = 0,
    read: usize = 0,

    fn remainder(self: *Rewriter) []const u8 {
        return self.buff[self.read..];
    }
    fn pull(self: *Rewriter) u8 {
        const val = self.buff[self.read];
        self.read += 1;
        return val;
    }
    fn writeVal(self: *Rewriter, val: u8) void {
        self.buff[self.write] = val;
        self.write += 1;
    }
    fn push(self: *Rewriter, val: u8) void {
        if (self.rules.get(val)) |rule| {
            // Checking the remainder for rule compliance
            const inva = blk: for (self.remainder()) |cell| {
                if (contains(rule.items, cell)) break :blk true;
            } else false;
            if (inva) {
                self.bag.appendAssumeCapacity(val);
                return;
            }
        }
        self.writeVal(val);
        self.handleStackDrain();
    }
    fn handleStackDrain(self: *Rewriter) void {
        _ = self;
    }
};
