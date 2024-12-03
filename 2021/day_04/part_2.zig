const std = @import("std");

var AllocState = std.heap.GeneralPurposeAllocator(.{}){};
const GPA = AllocState.allocator();

const TESTING = false;

pub fn main() !void {
    defer _ = AllocState.deinit();

    //=== FILE STUFF ===//
    const f = try if (TESTING)
        std.fs.cwd().openFile("test.txt", .{})
    else
        std.fs.cwd().openFile("input.txt", .{});
    const reader = f.reader().any();

    // reading the chosen numbers
    std.log.debug("reading numbers", .{});
    const buff = blk: {
        var buff_array = std.ArrayList(u8).init(GPA);
        try reader.streamUntilDelimiter(buff_array.writer(), '\n', null);
        const buff_thing = try buff_array.toOwnedSlice();
        buff_array.deinit();
        _ = try reader.readByte();
        break :blk buff_thing;
    };
    defer GPA.free(buff);

    // reading boards
    std.log.debug("reading boards", .{});
    var boards = std.ArrayList(*BingoBoard).init(GPA);
    defer {
        for (boards.items) |board| GPA.destroy(board);
        boards.deinit();
    }
    var fin = false;
    while (!fin) {
        var board_data: [BBRSize * 5]u8 = undefined;
        _ = try reader.read(&board_data);
        //std.log.debug("{s}", .{&board_data});
        const board = try BingoBoard.fromRepr(&board_data);
        try boards.append(board);
        fin = blk: {
            _ = reader.readByte() catch |err| switch (err) {
                error.EndOfStream => break :blk true,
                else => |x| return x,
            };
            break :blk false;
        };
    }
    std.log.debug("finished reading file", .{});
    f.close();

    var val: u8 = 0;
    outer: for (buff) |char| {
        if (std.ascii.isDigit(char)) {
            val = val * 10 + char - '0';
            continue;
        }
        var i: usize = 0;
        while (i < boards.items.len) {
            const board = boards.items[i];
            board.mark_num(val);
            if (!board.has_win()) {
                i += 1;
                continue;
            }
            if (boards.items.len > 1) {
                const old = boards.swapRemove(i);
                GPA.destroy(old);
                continue;
            }
            break :outer;
        }
        //std.log.debug("#boards: {}, val: {}", .{ boards.items.len, val });
        val = 0;
    }
    const board = boards.items[0];
    const score = board.sum_unmarked();
    std.log.debug("winning num: {} (score {})", .{ val, score });
    std.debug.print("{}\n", .{val * score});
    //return;
}

const BBRSize = 5 * 3;
const BingoBoard = struct {
    cells: [5][5]u8,
    marks: [5][5]bool,

    fn fromRepr(repr: []u8) !*BingoBoard {
        var out = try GPA.create(BingoBoard);
        errdefer GPA.destroy(out);
        for (0..5) |ri| {
            const rv = repr[ri * BBRSize .. (ri + 1) * BBRSize];
            for (0..5) |c| {
                const off: usize = c * 3;
                var val: u8 = 0;
                val += 10 * if (std.ascii.isDigit(rv[off + 0])) rv[off + 0] - '0' else 0;
                val += rv[off + 1] - '0';
                out.cells[ri][c] = val;
                out.marks[ri][c] = false;
            }
        }
        return out;
    }

    fn has_win(self: *const BingoBoard) bool {
        var col: [5]bool = undefined;
        for (0..5) |r| {
            if (all(&self.marks[r])) return true;
            for (0..5) |c| col[c] = self.marks[c][r];
            if (all(&col)) return true;
        }
        return false;
    }
    fn mark_num(self: *BingoBoard, num: u8) void {
        const cells: *const [25]u8 = @ptrCast(&self.cells);
        const marks: *[25]bool = @ptrCast(&self.marks);

        for (cells, marks) |cell, *mark| {
            if (cell != num) continue;
            mark.* = true;
            //return;
        }
    }
    fn sum_unmarked(self: *const BingoBoard) usize {
        var val: usize = 0;
        for (0..5) |r| for (0..5) |c| {
            if (self.marks[r][c]) continue;
            val += self.cells[r][c];
        };
        return val;
    }
};
fn all(xs: []const bool) bool {
    for (xs) |x| if (!x) return false;
    return true;
}
