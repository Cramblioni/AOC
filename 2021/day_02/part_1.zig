const std = @import("std");

var AllocState = std.heap.GeneralPurposeAllocator(.{}){};
const GPA = AllocState.allocator();

const TESTING = false;

pub fn main() !void {
    const f = try if (TESTING)
        std.fs.cwd().openFile("test.txt", .{})
    else
        std.fs.cwd().openFile("input.txt", .{});

    const contents = try GPA.alloc(u8, (try f.metadata()).size());
    defer GPA.free(contents);
    _ = try f.reader().readAll(contents);
    f.close();

    var position: isize = 0;
    var depth: isize = 0;

    var ind: usize = 0;
    var start = ind;
    while (ind < contents.len) {
        while (ind < contents.len and contents[ind] != '\n') {
            ind += 1;
        }
        const line = contents[start..ind];
        ind += 1;
        start = ind;

        std.log.debug("{}: {s}", .{ line.len, line });
        switch (line.len) {
            // ``
            0 => break,
            // `up X`
            4 => depth -= line[3] - '0',
            // `down X`
            6 => depth += line[5] - '0',
            // `forward X`
            9 => position += line[8] - '0',
            else => unreachable,
        }
    }
    std.debug.print("({},{}) {}\n", .{ position, depth, position * depth });
}
