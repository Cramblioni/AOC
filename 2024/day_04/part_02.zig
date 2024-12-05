const std = @import("std");

var AllocState = std.heap.GeneralPurposeAllocator(.{}){};
const GPA = AllocState.allocator();

const TESTING = false;

const LINELEN: u16 = if (TESTING) 10 else 140;

const GRID = [LINELEN][LINELEN]u8;

pub fn main() !void {
    defer _ = AllocState.deinit();
    const f = try if (TESTING)
        std.fs.cwd().openFile("test.txt", .{})
    else
        std.fs.cwd().openFile("input.txt", .{});

    var grid: GRID = undefined;
    for (0..LINELEN) |i| {
        var buff: [LINELEN + 1]u8 = undefined;
        _ = try f.read(&buff);
        @memcpy(&grid[i], buff[0..LINELEN]);
    }
    f.close();

    //const expects: [4]u8 = .{ 'X', 'M', 'A', 'S' };
    var count: usize = 0;
    for (1..LINELEN - 1) |r| for (1..LINELEN - 1) |c| {
        if (grid[r][c] != 'A') continue;
        const dd = (grid[r - 1][c - 1] == 'S' and grid[r + 1][c + 1] == 'M') or (grid[r - 1][c - 1] == 'M' and grid[r + 1][c + 1] == 'S');
        const ud = (grid[r + 1][c - 1] == 'S' and grid[r - 1][c + 1] == 'M') or (grid[r + 1][c - 1] == 'M' and grid[r - 1][c + 1] == 'S');
        if (dd and ud) {
            count += 1;
        }

        //const ds = valid(&grid, @intCast(r), @intCast(c), &expects);
        //std.log.debug("testing {},{}. Got {} hit/s", .{ r, c, ds });
        //count += ds;
    };
    std.debug.print("{}\n", .{count});
}

const Dir = enum {
    Inc,
    Eql,
    Dec,
    fn apply(self: Dir, x: u16) u16 {
        return switch (self) {
            .Inc => x + 1,
            .Eql => x,
            .Dec => x - 1,
        };
    }
};
const DIRS: [3]Dir = .{ .Inc, .Eql, .Dec };

fn valid(grid: *const GRID, row: u16, col: u16, wants: []const u8) u8 {
    var count: u8 = 0;
    for (DIRS) |r| for (DIRS) |c| {
        if (r == .Eql and c == .Eql) continue;

        if (r == .Dec and row == 0) continue;
        if (c == .Dec and col == 0) continue;
        if (r == .Inc and row == LINELEN - 1) continue;
        if (c == .Inc and col == LINELEN - 1) continue;

        if (!valid_run(grid, row, col, r, c, wants)) continue;
        count += 1;
    };
    return count;
}

fn valid_run(grid: *const GRID, row: u16, col: u16, dr: Dir, dc: Dir, wants: []const u8) bool {
    const head = wants[0];
    const tail = wants[1..];

    if (grid[@intCast(row)][@intCast(col)] != head) {
        return false;
    }
    if (tail.len == 0) {
        return true;
    }

    if (dr == .Dec and row == 0) return false;
    if (dc == .Dec and col == 0) return false;
    if (dr == .Inc and row == LINELEN - 1) return false;
    if (dc == .Inc and col == LINELEN - 1) return false;

    const nrow = dr.apply(row);
    const ncol = dc.apply(col);

    const res = valid_run(grid, nrow, ncol, dr, dc, tail);
    return res;
}
