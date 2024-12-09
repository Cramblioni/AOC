const std = @import("std");

var AllocState = std.heap.GeneralPurposeAllocator(.{}){};
const GPA = AllocState.allocator();

const TESTING = true;

const INPLEN: usize = (if (TESTING) 19 else 19_999);

pub fn main() !void {
    defer _ = AllocState.deinit();

    const contents = blk: {
        const path = if (TESTING) "test.txt" else "input.txt";
        const f = try std.fs.cwd().openFile(path, .{});
        const buff = try GPA.create([INPLEN]u8);
        _ = try f.read(buff);
        for (buff) |*cell| {
            cell.* -= '0';
        }
        break :blk buff;
    };
    errdefer GPA.destroy(contents);
    const map = try expand(contents);
    defer GPA.free(map);
    GPA.destroy(contents);

    for (map) |cell| if (cell == EMPTY)
        std.debug.print(".", .{})
    else
        std.debug.print("{}", .{cell});
    std.debug.print("\n", .{});

    reduce(map);

    var acc: usize = 0;
    for (0.., map) |i, cell| {
        if (cell == EMPTY) break;
        acc += @as(usize, cell) * i;
    }
    std.debug.print("{}\n", .{acc});
}

const EMPTY: u16 = 0xFFFF;
fn expand(inp: *const [INPLEN]u8) ![]u16 {
    var size: usize = 0;
    for (inp) |c| size += c;

    const buff = try GPA.alloc(u16, size);
    errdefer GPA.free(buff);

    var ind: usize = 0;
    var id: u16 = 0;
    for (0.., inp) |i, val| {
        if (i & 1 == 0) {
            shozzle(buff, val, id, &ind);
            id += 1;
        } else {
            shozzle(buff, val, EMPTY, &ind);
        }
    }
    return buff;
}

fn shozzle(buff: []u16, rep: u8, val: u16, ind: *usize) void {
    for (0..rep) |_| {
        buff[ind.*] = val;
        ind.* += 1;
    }
}

fn reduce(buff: []u16) void {
    if (buff.len == 0) return;
    var bound: usize = 0;
    for (buff) |cell| if (cell != EMPTY) {
        bound += 1;
    };

    var write: usize = 0;
    var pull: usize = buff.len - 1;
    while (write + 2 < bound) {
        while (buff[write] != EMPTY) write += 1;
        buff[write] = buff[pull];
        buff[pull] = EMPTY;
        while (buff[pull] == EMPTY) pull -= 1;
    }
}
