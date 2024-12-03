const std = @import("std");

var AllocState = std.heap.GeneralPurposeAllocator(.{}){};
const GPA = AllocState.allocator();

const TESTING = false;
const WORDSIZE: usize = if (TESTING) 5 else 12;

pub fn main() !void {
    defer _ = AllocState.deinit();
    const f = try if (TESTING)
        std.fs.cwd().openFile("test.txt", .{})
    else
        std.fs.cwd().openFile("input.txt", .{});

    const contents = try GPA.alloc(u8, (try f.metadata()).size());
    defer GPA.free(contents);
    _ = try f.reader().readAll(contents);
    f.close();

    var i: usize = 0;
    var buckets: [WORDSIZE][2]usize = undefined;
    @memset(&buckets, .{ 0, 0 });
    while (i < contents.len) {
        for (0.., contents[i .. i + WORDSIZE]) |j, x| {
            if (x == '1') buckets[j][1] += 1 else buckets[j][0] += 1;
        }
        i += WORDSIZE + 1;
    }

    var gamma: usize = 0;
    for (buckets) |bucket| {
        const sel = @intFromBool(bucket[1] > bucket[0]);
        gamma = (gamma << 1) + sel;
    }
    var epsilon: usize = 0;
    for (buckets) |bucket| {
        const sel = @intFromBool(bucket[0] > bucket[1]);
        epsilon = (epsilon << 1) + sel;
    }
    std.debug.print("{}\n", .{gamma * epsilon});
}
