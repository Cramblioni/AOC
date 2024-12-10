const std = @import("std");

var AllocState = std.heap.GeneralPurposeAllocator(.{}){};
const GPA = AllocState.allocator();

const TESTING = false;

const SIZE: usize = if (TESTING) 8 else 53;

const Grid = [SIZE * SIZE]u8;

pub fn main() !void {
    defer _ = AllocState.deinit();

    const grid = try GPA.create(Grid);
    defer GPA.destroy(grid);
    {
        const path = if (TESTING) "test.txt" else "input.txt";
        const f = try std.fs.cwd().openFile(path, .{});
        for (0..SIZE) |r| {
            const start = r * SIZE;
            _ = if (start + SIZE + 1 > grid.len)
                try f.read(grid[start .. start + SIZE])
            else
                try f.read(grid[start .. start + SIZE + 1]);
        }
        for (grid) |*c| c.* -= '0';
    }

    var score: usize = 0;
    for (0..SIZE) |r| for (0..SIZE) |c| {
        if (grid[r * SIZE + c] != 0) continue;
        const res = try follow(grid, @intCast(r), @intCast(c));
        score += res;
    };
    std.debug.print("\nscore: {}\n", .{score});
}

const Pos = struct {
    r: u32,
    c: u32,
    fn toInd(self: Pos) usize {
        return @as(usize, self.r) * SIZE + self.c;
    }
    fn tcDist(self: Pos, oth: Pos) usize {
        return dif(self.r, oth.r) + dif(self.c, oth.c);
    }
    fn findNearest(self: Pos, ps: []const Pos) usize {
        var mind: usize = 0;
        var mdist: usize = 0xFFFFFFFF;
        for (0.., ps) |i, pos| {
            const dist = self.tcDist(pos);
            if (dist > mdist) continue;
            mdist = dist;
            mind = i;
        }
        return mind;
    }
};
fn follow(grid: *const Grid, r: u32, c: u32) !usize {
    var open_set = try std.ArrayListUnmanaged(Pos).initCapacity(GPA, SIZE * SIZE);
    defer open_set.deinit(GPA);
    const closed_set = try GPA.alloc(bool, SIZE * SIZE);
    @memset(closed_set, false);
    defer GPA.free(closed_set);

    open_set.appendAssumeCapacity(.{ .r = r, .c = c });
    while (open_set.items.len > 0) {
        const cur = blk: {
            const ind = (Pos{ .r = r, .c = c }).findNearest(open_set.items);
            break :blk open_set.swapRemove(ind);
        };
        closed_set[cur.toInd()] = true;
        if (grid[cur.toInd()] == 9) {
            continue;
        }
        if (cur.r > 0) {
            const new: Pos = .{ .r = cur.r - 1, .c = cur.c };
            if (!closed_set[new.toInd()] and validMove(grid[cur.toInd()], grid[new.toInd()]))
                open_set.appendAssumeCapacity(new);
        }
        if (cur.r + 1 < SIZE) {
            const new: Pos = .{ .r = cur.r + 1, .c = cur.c };
            if (!closed_set[new.toInd()] and validMove(grid[cur.toInd()], grid[new.toInd()]))
                open_set.appendAssumeCapacity(new);
        }
        if (cur.c > 0) {
            const new: Pos = .{ .r = cur.r, .c = cur.c - 1 };
            if (!closed_set[new.toInd()] and validMove(grid[cur.toInd()], grid[new.toInd()]))
                open_set.appendAssumeCapacity(new);
        }
        if (cur.c + 1 < SIZE) {
            const new: Pos = .{ .r = cur.r, .c = cur.c + 1 };
            if (!closed_set[new.toInd()] and validMove(grid[cur.toInd()], grid[new.toInd()]))
                open_set.appendAssumeCapacity(new);
        }
    }
    //std.log.debug("printing", .{});
    var score: usize = 0;
    for (0..SIZE) |mr| {
        for (0..SIZE) |mc| {
            if (closed_set[mr * SIZE + mc]) {
                if (grid[mr * SIZE + mc] == 9) score += 1;
                //std.debug.print("\x1b[7m{}\x1b[27m", .{grid[mr * SIZE + mc]});
            } // else std.debug.print("{}", .{grid[mr * SIZE + mc]});
        }
        //std.debug.print("\n", .{});
    }
    return score;
}

fn validMove(from: u8, to: u8) bool {
    if (from > to) return false else return to - from == 1;
}
fn dif(from: anytype, to: @TypeOf(from)) @TypeOf(from) {
    if (from > to) return from - to else return to - from;
}
