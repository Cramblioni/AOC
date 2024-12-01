const std = @import("std");
const Reader = std.io.AnyReader;

const TESTING = false;
const NUMSIZE: u8 = if (TESTING) 1 else 5;
const BUFFSIZE: u8 = (NUMSIZE * 2 + 3) + 2; // (line contents) + (line ending)

var AllocState = std.heap.GeneralPurposeAllocator(.{}){};
const GPA = AllocState.allocator();

pub fn main() !void {
    defer _ = AllocState.deinit();
    // open input
    const source_file = try if (TESTING)
        std.fs.cwd().openFile("test.txt", .{})
    else
        std.fs.cwd().openFile("input.txt", .{});
    // read input
    var reader = source_file.reader();
    var buff: [BUFFSIZE]u8 = undefined;
    var list_a = std.ArrayList(u32).init(GPA);
    defer list_a.deinit();
    var list_b = std.ArrayList(u32).init(GPA);
    defer list_b.deinit();

    while (try reader.readUntilDelimiterOrEof(&buff, '\n')) |line| {
        try list_a.append(strToInt(line[0..NUMSIZE]));
        try list_b.append(strToInt(line[NUMSIZE + 3 .. NUMSIZE * 2 + 3]));
    }
    // cleanup file stuff
    source_file.close();
    // count the right list
    var map = std.AutoHashMap(u32, u32).init(GPA);
    defer map.deinit();

    for (list_b.items) |b| {
        const entry = try map.getOrPut(b);
        if (entry.found_existing) {
            entry.value_ptr.* += 1;
        } else {
            entry.value_ptr.* = 1;
        }
    }
    var total: u32 = 0;
    for (list_a.items) |a| {
        const count = if (map.getPtr(a)) |x| x.* else 0;
        total += a * count;
    }
    try std.io.getStdOut().writer().print("{}\n", .{total});
}

// Return 0 on empty
fn strToInt(inp: []const u8) u32 {
    var out: u32 = 0;
    for (inp) |char|
        out = out * 10 + (char - '0');
    return out;
}
