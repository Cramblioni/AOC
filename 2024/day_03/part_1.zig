const std = @import("std");
const AnyReader = std.io.AnyReader;

const TESTING = false;

pub fn main() !void {
    const f = try if (TESTING)
        std.fs.cwd().openFile("test.txt", .{})
    else
        std.fs.cwd().openFile("input.txt", .{});
    defer f.close();
    const reader = f.reader().any();
    var parser = try Parser.new(reader);

    var val: usize = 0;
    while (!parser.at_end()) {
        if (try pullMul(&parser)) |product| val += product;
    }
    std.debug.print("{}\n", .{val});
}

fn pullMul(parser: *Parser) !?usize {
    //std.log.debug("pulling mul", .{});
    //const logger = std.log.scoped(.mul_puller);
    //logger.debug("getting head", .{});
    if (!try parser.literal("mul(")) return null;
    //logger.debug("getting number a", .{});
    const a = if (try parser.number()) |x| x else return null;
    if (!try parser.byte(',')) return null;
    //logger.debug("getting number b", .{});
    const b = if (try parser.number()) |x| x else return null;
    if (!try parser.byte(')')) return null;
    std.log.debug("{} * {}", .{ a, b });
    return a * b;
}

const Parser = struct {
    reader: AnyReader,
    buff: [256]u8 = undefined,
    size: usize = 0,
    ind: usize = 0,

    fn new(reader: AnyReader) !Parser {
        var out: Parser = .{ .reader = reader };
        try out.handle_buff_fill();
        return out;
    }

    fn handle_buff_fill(self: *Parser) !void {
        if (self.ind < self.size) return;
        self.size = try self.reader.read(&self.buff);
        self.ind = 0;
    }

    fn peek(self: *const Parser) u8 {
        return self.buff[self.ind];
    }
    fn consume(self: *Parser) !u8 {
        const ret = self.peek();
        self.ind += 1;
        try self.handle_buff_fill();
        return ret;
    }
    fn literal(self: *Parser, lit: []const u8) !bool {
        //std.log.debug("pulling literal", .{});
        for (lit) |char| {
            if (try self.consume() != char) return false;
        }
        return true;
    }
    fn at_end(self: *const Parser) bool {
        return self.size == 0;
    }
    fn number(self: *Parser) !?usize {
        //std.log.debug("pulling number", .{});
        const BUFFSIZE = 10;
        var inner_buff: [BUFFSIZE]u8 = undefined;
        var ind: usize = 0;
        while (std.ascii.isDigit(self.peek()) and ind < BUFFSIZE) {
            inner_buff[ind] = try self.consume();
            ind += 1;
        }
        if (ind == 0) return null;
        var val: usize = 0;
        for (inner_buff[0..ind]) |digit| {
            val = (val * 10) + (digit - '0');
        }
        return val;
    }
    fn byte(self: *Parser, char: u8) !bool {
        if (self.peek() != char) return false;
        _ = try self.consume();
        return true;
    }
};
