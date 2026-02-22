const std = @import("std");
const tokenize = @import("tokenizer.zig").tokenize;
const json = std.json;
const Token = @import("Token.zig");

pub fn parse(comptime T: type, allocator: std.mem.Allocator, src: []const u8, tokens: []Token, option: json.ParseOptions) !json.Parsed(T) {
    const stripped = try stripComment(allocator, src, tokens);
    defer allocator.free(stripped);

    return try json.parseFromSlice(T, allocator, stripped, option);
}

fn stripComment(allocator: std.mem.Allocator, src: []const u8, tokens: []Token) ![]u8 {
    var stripped = std.ArrayList(u8){};
    errdefer stripped.deinit(allocator);

    var i: usize = 0;
    while (i < tokens.len) {
        const token = tokens[i];
        switch (token.kind) {
            .line_comment, .block_comment => i += 1,
            .invalid => return error.InvalidJson,
            else => {
                const slice = src[token.start..token.end];
                try stripped.appendSlice(allocator, slice);
                i += 1;
            },
        }
    }

    return stripped.toOwnedSlice(allocator);
}
