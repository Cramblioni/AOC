const std = @import("std");

var AllocState = std.heap.GeneralPurposeAllocator(.{}){};
const GPA = AllocState.allocator();

const TESTING = false;

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

    //showBlocks(map);
    const new_map = try reduce(map);
    defer GPA.free(new_map);
    //showBlocks(new_map);

    var base: usize = 0;
    var checksum: usize = 0;
    for (new_map) |block| {
        for (base..base + block.len) |i| checksum += i * block.id.?;
        base += block.len;
    }
    std.debug.print("{}\n", .{checksum});
}

const Block = struct { id: ?u16 = null, len: u8 };

fn expand(inp: *const [INPLEN]u8) ![]Block {
    var out = std.ArrayList(Block).init(GPA);
    defer out.deinit();

    var id: u16 = 0;
    for (0.., inp) |i, val| {
        if (i & 1 == 0) {
            try out.append(.{ .id = id, .len = val });
            id += 1;
        } else {
            try out.append(.{ .len = val });
        }
    }
    return try out.toOwnedSlice();
}

const BlockDeque = std.DoublyLinkedList(Block);
fn reduce(blocks: []Block) ![]Block {
    var arena_state = std.heap.ArenaAllocator.init(GPA);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    // creating deque
    var block_deque = BlockDeque{};
    for (blocks) |block| {
        const node = try arena.create(BlockDeque.Node);
        node.data = block;
        block_deque.append(node);
    }

    var out = try std.ArrayList(Block).initCapacity(GPA, blocks.len);
    defer out.deinit();

    while (block_deque.first) |head| {
        if (head.data.id != null) {
            // squish checking
            if (head.next) |next| if (next.data.id == head.data.id) {
                head.data.len += next.data.len;
                head.next = next.next; // squishing
                block_deque.len -= 1;
                continue;
            };
            // Head is a full block and not to be squished
            out.appendAssumeCapacity(head.data);
            _ = block_deque.popFirst();
            continue;
        }
        // head is empty
        if (block_deque.len == 1) break; // We ignore trailing empty block

        const tail = block_deque.last.?; // This shouldn't be null
        if (tail.data.id == null) {
            // If we encounter an empty block, skip it.
            _ = block_deque.pop();
            continue;
        }
        if (tail.data.len == head.data.len) {
            // If we can directly substitue,
            //      then replace head and redo this step
            _ = block_deque.popFirst();
            block_deque.prepend(block_deque.pop().?);
            continue;
        }

        if (tail.data.len > head.data.len) {
            // Split tail into two then
            //  Replace head filled with tail
            //  Replace tail with remaining parts
            _ = block_deque.popFirst(); // head
            const new_head_block = Block{ .id = tail.data.id, .len = head.data.len };
            tail.data.len -= head.data.len; // replacing the last len
            const new_head = try arena.create(BlockDeque.Node);
            new_head.data = new_head_block;
            block_deque.prepend(new_head);
            continue;
        }

        if (tail.data.len < head.data.len) {
            // Split head into two
            //  Fill replace the first part with tail
            head.data.len -= tail.data.len;
            _ = block_deque.pop();
            block_deque.prepend(tail);
            continue;
        }
    }
    return try out.toOwnedSlice();
}

fn showBlocks(blocks: []Block) void {
    for (blocks) |block| {
        if (block.id) |id| {
            std.debug.print("[{x:0>2}*{}] ", .{ id, block.len });
        } else std.debug.print("[.*{}] ", .{block.len});
    }
    std.debug.print("\n", .{});
}
