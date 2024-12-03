const std = @import("std");

// avoiding creating functions

var AllocState = std.heap.GeneralPurposeAllocator(.{}){};
const GPA = AllocState.allocator();

const TESTING = false;

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

    var ind: usize = 0;
    var prev: usize = std.math.maxInt(usize);
    var count: usize = 0;

    while (ind < contents.len) {
        var val: usize = 0;
        while (ind < contents.len and contents[ind] != '\n') {
            val = (val * 10) + (contents[ind] - '0');
            ind += 1;
        }
        ind += 1;
        if (val > prev) count += 1;
        prev = val;
    }
    std.debug.print("{}\n", .{count});
}
