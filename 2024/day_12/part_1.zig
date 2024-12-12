const std = @import("std");

var AllocState = std.heap.GeneralPurposeAllocator(.{}){};
const GPA = AllocState.allocator();

const TESTING = false;

const SIZE = if (TESTING) 10 else 140;

const GRID = [SIZE * SIZE]u8;
const BGRID = [SIZE * SIZE]bool;

pub fn main() !void {
    defer _ = AllocState.deinit();
    const grid = try GPA.create(GRID);
    defer GPA.destroy(grid);
    {
        const path = if (TESTING) "test.txt" else "input.txt";
        const f = try std.fs.cwd().openFile(path, .{});
        defer f.close();
        var lbuff: [SIZE + 1]u8 = undefined;
        for (0..SIZE) |r| {
            _ = try f.read(&lbuff);
            @memcpy(grid[r * SIZE .. r * SIZE + SIZE], lbuff[0..SIZE]);
        }
    }
    //for (0..SIZE) |r| {
    //    std.log.debug("{s}", .{grid[r * SIZE .. r * SIZE + SIZE]});
    //}
    const marks = try GPA.create(BGRID);
    defer GPA.destroy(marks);
    @memset(marks, false);

    var score: usize = 0;
    for (1..SIZE * SIZE) |c| {
        if (marks[c]) continue;
        const al = try getArea(grid, marks, c);
        //std.log.info("region {c}: {}", .{ grid[c], al });
        score += al.area * (al.perimeter - @intFromBool(score == 0));
    }
    std.debug.print("{}\n", .{score});
}

const Region = struct { area: usize, perimeter: usize };
fn getArea(grid: *const GRID, marks: *BGRID, start: usize) !Region {
    var todo = std.ArrayList(usize).init(GPA);
    const expect = grid[start];
    //std.log.debug("finding area for {c}", .{expect});
    defer todo.deinit();
    try todo.append(start);

    var area: usize = 0;
    var perimeter: usize = 0;
    while (todo.popOrNull()) |pos| {
        if (marks[pos]) continue;
        if (grid[pos] != expect) continue;
        marks[pos] = true;
        area += 1;
        // testing up
        if (pos > SIZE and grid[pos - SIZE] == expect) {
            if (!marks[pos - SIZE]) try todo.append(pos - SIZE);
        } else perimeter += 1;
        // testing down
        if (pos + SIZE < SIZE * SIZE and grid[pos + SIZE] == expect) {
            if (!marks[pos + SIZE]) try todo.append(pos + SIZE);
        } else perimeter += 1;
        // testing right
        if (pos % SIZE + 1 < SIZE and grid[pos + 1] == expect) {
            if (!marks[pos + 1]) try todo.append(pos + 1);
        } else perimeter += 1;
        // testing left
        if (pos % SIZE > 0 and grid[pos - 1] == expect) {
            if (!marks[pos - 1]) try todo.append(pos - 1);
        } else perimeter += 1;
    }
    return .{ .area = area, .perimeter = perimeter };
}
