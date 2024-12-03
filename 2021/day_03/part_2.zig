const std = @import("std");

var AllocState = std.heap.GeneralPurposeAllocator(.{}){};
const GPA = AllocState.allocator();

const TESTING = false;

const WORDSIZE: usize = if (TESTING) 5 else 12;
const WORD = u32; //@Type(.{ .Int = .{ .signedness = .unsigned, .bits = WORDSIZE } });

pub fn main() !void {
    defer _ = AllocState.deinit();
    const f = try if (TESTING)
        std.fs.cwd().openFile("test.txt", .{})
    else
        std.fs.cwd().openFile("input.txt", .{});

    const contents = try GPA.alloc(u8, (try f.metadata()).size());
    _ = try f.reader().readAll(contents);
    f.close();
    const count: usize = try std.math.divCeil(usize, contents.len, (WORDSIZE + 1));
    const nums = try GPA.alloc(WORD, count);
    defer GPA.free(nums);
    for (0..count) |i| {
        const word = contents[i * (WORDSIZE + 1) .. i * (WORDSIZE + 1) + WORDSIZE];
        var temp: WORD = 0;
        for (word) |char| temp = @intCast((temp << 1) + (char - '0'));
        nums[i] = temp;
    }
    GPA.free(contents);
    const nums2 = try GPA.alloc(WORD, count);
    defer GPA.free(nums2);

    const oxy = blk: {
        var prev = nums;
        var cur = nums2;
        var i: u4 = WORDSIZE;
        while (i > 0 and prev.len != 1) {
            i -%= 1;
            const nlen = doFilter(prev, cur, i, 1);
            prev = cur[0..nlen];
        }
        break :blk prev[0];
    };

    const co2 = blk: {
        var prev = nums;
        var cur = nums2;
        var i: u4 = WORDSIZE;
        while (i > 0 and prev.len != 1) {
            i -%= 1;
            const nlen = doFilter(prev, cur, i, 0);
            prev = cur[0..nlen];
        }
        break :blk prev[0];
    };
    std.log.debug("{}", .{oxy * co2});
}

fn doFilter(buff: []const WORD, dest: []WORD, ind: u4, bias: u1) usize {
    const sel: u1 = blk: {
        var buckets: [2]usize = undefined;
        for (buff) |num| {
            buckets[(num >> ind) & 1] += 1;
        }
        if (bias == 1) {
            if (buckets[0] > buckets[1])
                break :blk 0
            else if (buckets[1] > buckets[0])
                break :blk 1
            else
                break :blk bias;
        } else {
            if (buckets[0] > buckets[1])
                break :blk 1
            else if (buckets[1] > buckets[0])
                break :blk 0
            else
                break :blk bias;
        }
    };

    var write: usize = 0;
    for (buff) |num| {
        if ((num >> ind) & 1 != sel) continue;
        dest[write] = num;
        write += 1;
    }
    return write;
}
