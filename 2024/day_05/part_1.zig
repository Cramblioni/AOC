const std = @import("std");

const TESTING = false;

var AllocState = std.heap.GeneralPurposeAllocator(.{}){};
const GPA = AllocState.allocator();

pub fn main() !void {
    defer _ = AllocState.deinit();

    const f = try if (TESTING)
        std.fs.cwd().openFile("test.txt", .{})
    else
        std.fs.cwd().openFile("input.txt", .{});

    const reader = f.reader().any();

    // Reading ordering
    var mapping = std.AutoHashMap(u8, std.ArrayList(u8)).init(GPA);
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
        if (!validateUpdate(&mapping, update.items)) continue;
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

fn validateUpdate(rules: *std.AutoHashMap(u8, std.ArrayList(u8)), update: []const u8) bool {
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
