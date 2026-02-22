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
            .line_comment => i += 1,
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

const testing = std.testing;

test "object key-value pair with line_comment" {
    const allocator = testing.allocator;
    const src =
        \\ {
        \\  // This is comment
        \\  "key": "value"
        \\ }
    ;

    const tokens = try tokenize(allocator, src);
    defer allocator.free(tokens);

    const parsed = try parse(json.Value, allocator, src, tokens, .{});
    defer parsed.deinit();

    try testing.expect(parsed.value == .object);
    try testing.expectEqualStrings("value", parsed.value.object.get("key").?.string);
}

test "array with line_comment" {
    const allocator = testing.allocator;
    const src =
        \\ [
        \\  // This is a comment
        \\  "apple", "orange", "grape"
        \\ ]
    ;

    const tokens = try tokenize(allocator, src);
    defer allocator.free(tokens);

    const parsed = try parse(json.Value, allocator, src, tokens, .{});
    defer parsed.deinit();

    try testing.expect(parsed.value == .array);
    try testing.expectEqualStrings("apple", parsed.value.array.items[0].string);
    try testing.expectEqualStrings("orange", parsed.value.array.items[1].string);
    try testing.expectEqualStrings("grape", parsed.value.array.items[2].string);
}

test "array with line_comment 2" {
    const allocator = testing.allocator;
    const src =
        \\ [
        \\  // This is a comment
        \\  "apple", "orange", "grape"
        \\ ]
    ;

    const tokens = try tokenize(allocator, src);
    defer allocator.free(tokens);

    const parsed = try parse(json.Value, allocator, src, tokens, .{});
    defer parsed.deinit();

    try testing.expect(parsed.value == .array);
    try testing.expectEqualStrings("apple", parsed.value.array.items[0].string);
    try testing.expectEqualStrings("orange", parsed.value.array.items[1].string);
    try testing.expectEqualStrings("grape", parsed.value.array.items[2].string);
}
