const std = @import("std");

const TESTING = false;

var AllocState = std.heap.GeneralPurposeAllocator(.{}){};
const GPA = AllocState.allocator();

const SIZE: struct { w: u16, h: u16 } = if (TESTING)
    .{ .w = 10, .h = 10 }
else
    .{ .w = 130, .h = 130 };

const Cell = enum { Empty, Wall, Guard };
const Dir = enum { Up, Down, Left, Right };
const Grid = [SIZE.h][SIZE.w]bool;

const Guard = struct {
    r: u16,
    c: u16,
    d: Dir = .Up,
};

pub fn main() !void {
    defer _ = AllocState.deinit();

    const f = try std.fs.cwd().openFile(
        if (TESTING) "test.txt" else "input.txt",
        .{},
    );
    // reading file
    const grid = try GPA.create(Grid);
    defer GPA.destroy(grid);
    var guard: Guard = undefined;
    try parseFile(f, grid, &guard);
    f.close();

    // prepping for the walk
    const walkmap = try GPA.create(Grid);
    defer GPA.destroy(walkmap);
    @memset(@as(*[SIZE.w * SIZE.h]bool, @ptrCast(walkmap)), false);

    // Doing the walk
    while (true) {
        // marking location
        walkmap[guard.r][guard.c] = true;
        // check if moving will leave the map
        switch (guard.d) {
            .Up => if (guard.r == 0) break,
            .Down => if (guard.r + 1 >= SIZE.h) break,
            .Left => if (guard.c == 0) break,
            .Right => if (guard.c + 1 >= SIZE.w) break,
        }
        // Do player move
        const cannot = switch (guard.d) {
            .Up => grid[guard.r - 1][guard.c],
            .Down => grid[guard.r + 1][guard.c],
            .Left => grid[guard.r][guard.c - 1],
            .Right => grid[guard.r][guard.c + 1],
        };
        if (cannot) {
            guard.d = switch (guard.d) {
                .Up => .Right,
                .Down => .Left,
                .Left => .Up,
                .Right => .Down,
            };
            continue;
        }
        switch (guard.d) {
            .Up => guard.r -= 1,
            .Down => guard.r += 1,
            .Left => guard.c -= 1,
            .Right => guard.c += 1,
        }
    }
    // counting stepped on cells
    var count: usize = 0;
    for (@as(*[SIZE.w * SIZE.h]bool, @ptrCast(walkmap))) |cell|
        count += @intFromBool(cell);
    std.debug.print("{}\n", .{count});
}

fn parseFile(f: std.fs.File, grid: *Grid, guard: *Guard) !void {
    var buff: [SIZE.w + 1]u8 = undefined;
    for (0..SIZE.h) |r| {
        _ = try f.read(&buff);
        for (0..SIZE.w) |c| {
            switch (buff[c]) {
                '#' => grid[r][c] = true,
                '.' => grid[r][c] = false,
                '^' => guard.* = .{ .r = @intCast(r), .c = @intCast(c) },
                else => unreachable,
            }
        }
    }
}
