pub const std = @import("std");
pub const Jsonc = @This();
const tokenize = @import("tokenizer.zig").tokenize;
const parse_jsonc = @import("parser.zig").parse;

src_text: []const u8,

pub fn init(src_text: []const u8) Jsonc {
    return .{
        .src_text = src_text,
    };
}

pub fn parse(self: *Jsonc, comptime T: type, allocator: std.mem.Allocator, option: std.json.ParseOptions) !std.json.Parsed(T) {
    const tokenized = try tokenize(allocator, self.src_text);
    defer allocator.free(tokenized);

    return parse_jsonc(T, allocator, self.src_text, tokenized, option);
}

pub fn deinit(self: *Jsonc) void {
    _ = self;
}
