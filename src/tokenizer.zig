const std = @import("std");
const Token = @import("Token.zig");
const TokenKind = @import("Token.zig").TokenKind;

pub fn tokenize(allocator: std.mem.Allocator, src: []const u8) ![]Token {
    var list = std.ArrayList(Token){};
    defer list.deinit(allocator);

    var i: usize = 0;
    while (i < src.len) {
        const start = i;
        const char = src[i];
        switch (char) {
            '{' => {
                try list.append(allocator, .{ .kind = .lbrace, .start = @intCast(start), .end = @intCast(start + 1) });
                i += 1;
            },
            '}' => {
                try list.append(allocator, .{ .kind = .rbrace, .start = @intCast(start), .end = @intCast(i + 1) });
                i += 1;
            },
            '[' => {
                try list.append(allocator, .{ .kind = .lbracket, .start = @intCast(start), .end = @intCast(i + 1) });
                i += 1;
            },
            ']' => {
                try list.append(allocator, .{ .kind = .rbracket, .start = @intCast(start), .end = @intCast(i + 1) });
                i += 1;
            },
            ':' => {
                try list.append(allocator, .{ .kind = .colon, .start = @intCast(start), .end = @intCast(i + 1) });
                i += 1;
            },
            ',' => {
                try list.append(allocator, .{ .kind = .comma, .start = @intCast(start), .end = @intCast(i + 1) });
                i += 1;
            },
            // string
            '"' => {
                i += 1;
                while (i < src.len) {
                    if (src[i] == '\\') {
                        i += 2; // skip escape
                    } else if (src[i] == '"') {
                        i += 1;
                        break;
                    } else {
                        i += 1;
                    }
                }
                try list.append(allocator, .{ .kind = .string, .start = @intCast(start), .end = @intCast(i) });
            },

            // number
            '-', '0'...'9' => {
                i += 1;
                while (i < src.len and switch (src[i]) {
                    '0'...'9', '.', 'e', 'E', '+', '-' => true,
                    else => false,
                }) : (i += 1) {}
                try list.append(allocator, .{ .kind = .number, .start = @intCast(start), .end = @intCast(i) });
            },
            // true, false, null and comment
            't', 'f', 'n', '/' => {
                if (char == '/' and i + 1 < src.len and src[i + 1] == '/') {
                    // line comment
                    while (i < src.len and src[i] != '\n') : (i += 1) {}
                    try list.append(allocator, .{ .kind = .line_comment, .start = @intCast(start), .end = @intCast(i) });
                    // TODO Fix block comment implementation
                } else if (char == '/' and i + 1 < src.len and src[i + 1] == '*') {
                    // block comment
                    i += 2;
                    var closed = false;
                    while (i < src.len) : (i += 1) {
                        if (src[i] == '*' and i < src.len and src[i + 1] == '/') {
                            i += 2;
                            try list.append(allocator, .{ .kind = .block_comment, .start = @intCast(start), .end = @intCast(i) });
                            closed = true;
                            break;
                        } else {
                            continue;
                        }
                    }
                    if (!closed) {
                        return error.InvalidComment;
                    }
                } else if (std.mem.startsWith(u8, src[i..], "true")) {
                    try list.append(allocator, .{ .kind = .true, .start = @intCast(start), .end = @intCast(i + 4) });
                    i += 4;
                } else if (std.mem.startsWith(u8, src[i..], "false")) {
                    try list.append(allocator, .{ .kind = .false, .start = @intCast(start), .end = @intCast(i + 5) });
                    i += 5;
                } else if (std.mem.startsWith(u8, src[i..], "null")) {
                    try list.append(allocator, .{ .kind = .null, .start = @intCast(start), .end = @intCast(i + 4) });
                    i += 4;
                } else {
                    try list.append(allocator, .{ .kind = .invalid, .start = @intCast(start), .end = @intCast(i + 1) });
                    i += 1;
                }
            },
            '\n' => {
                try list.append(allocator, .{ .kind = .newline, .start = @intCast(start), .end = @intCast(i + 1) });
                i += 1;
            },
            ' ', '\t', '\r' => {
                while (i < src.len and (src[i] == ' ' or src[i] == '\t' or src[i] == '\r')) : (i += 1) {}
                try list.append(allocator, .{ .kind = .whitespace, .start = @intCast(start), .end = @intCast(i) });
            },
            else => {
                try list.append(allocator, .{ .kind = .invalid, .start = @intCast(start), .end = @intCast(i + 1) });
                i += 1;
            },
        }
    }

    try list.append(allocator, .{ .kind = .eof, .start = @intCast(src.len), .end = @intCast(src.len) });
    return try list.toOwnedSlice(allocator);
}

const testing = std.testing;

/// Helper function for testing
fn expectKinds(result: []const Token, expected: []const TokenKind) !void {
    try testing.expectEqual(expected.len, result.len);
    for (expected, result) |exp, got| {
        try testing.expectEqual(exp, got.kind);
    }
}

/// Helper function for testing
fn expectSlice(token: Token, src: []const u8, expected: []const u8) !void {
    try testing.expectEqualStrings(expected, token.slice(src));
}

test "empty object" {
    const src = "{}";
    const result = try tokenize(testing.allocator, src);
    defer testing.allocator.free(result);

    try expectKinds(result, &.{ .lbrace, .rbrace, .eof });
}

test "empty list" {
    const src = "[]";
    const result = try tokenize(testing.allocator, src);
    defer testing.allocator.free(result);

    try expectKinds(result, &.{ .lbracket, .rbracket, .eof });
}

test "true" {
    const src = "true";
    const result = try tokenize(testing.allocator, src);
    defer testing.allocator.free(result);

    try expectKinds(result, &.{ .true, .eof });
}

test "false" {
    const src = "false";
    const result = try tokenize(testing.allocator, src);
    defer testing.allocator.free(result);

    try expectKinds(result, &.{ .false, .eof });
}

test "null" {
    const src = "null";
    const result = try tokenize(testing.allocator, src);
    defer testing.allocator.free(result);

    try expectKinds(result, &.{ .null, .eof });
}

test "number" {
    const src = "23";
    const result = try tokenize(testing.allocator, src);
    defer testing.allocator.free(result);

    try expectKinds(result, &.{ .number, .eof });
}

test "negative number" {
    const src = "-23";
    const result = try tokenize(testing.allocator, src);
    defer testing.allocator.free(result);

    try expectKinds(result, &.{ .number, .eof });
}

test "float number" {
    const src = "3.14";
    const result = try tokenize(testing.allocator, src);
    defer testing.allocator.free(result);

    try expectKinds(result, &.{ .number, .eof });
}

test "negative float number" {
    const src = "-3.14";
    const result = try tokenize(testing.allocator, src);
    defer testing.allocator.free(result);

    try expectKinds(result, &.{ .number, .eof });
}

test "number float" {
    const src = "3.14159";
    const result = try tokenize(testing.allocator, src);
    defer testing.allocator.free(result);

    try testing.expectEqual(2, result.len);
    try testing.expectEqual(.number, result[0].kind);
    try expectSlice(result[0], src, "3.14159");
}

test "number exponential" {
    const src = "1.5e+10";
    const result = try tokenize(testing.allocator, src);
    defer testing.allocator.free(result);

    try testing.expectEqual(2, result.len);
    try testing.expectEqual(.number, result[0].kind);
}

test "number negative exponential" {
    const src = "-2.5E-3";
    const result = try tokenize(testing.allocator, src);
    defer testing.allocator.free(result);

    try testing.expectEqual(2, result.len);
    try testing.expectEqual(.number, result[0].kind);
}

test "number zero" {
    const src = "0";
    const result = try tokenize(testing.allocator, src);
    defer testing.allocator.free(result);

    try testing.expectEqual(2, result.len);
    try testing.expectEqual(.number, result[0].kind);
}
test "string" {
    const text = "{\"key\": \"value\"}";
    const allocator = testing.allocator;

    const result = try tokenize(allocator, text);
    defer allocator.free(result);

    try testing.expectEqual(7, result.len);
}

test "string empty" {
    const src = "\"\"";
    const result = try tokenize(testing.allocator, src);
    defer testing.allocator.free(result);

    try testing.expectEqual(2, result.len);
    try testing.expectEqual(.string, result[0].kind);
    try expectSlice(result[0], src, "\"\"");
}

test "key-value pair" {
    const src = "{\"key\": \"value\"}";
    const allocator = testing.allocator;

    const result = try tokenize(allocator, src);
    defer allocator.free(result);

    try testing.expectEqual(7, result.len);
}

test "number array" {
    const src = "[2, 2, 3]";
    const allocator = testing.allocator;

    const result = try tokenize(allocator, src);
    defer allocator.free(result);

    try testing.expectEqual(10, result.len);
}

test "line comment" {
    const src = "// this is a comment\n";
    const result = try tokenize(testing.allocator, src);
    defer testing.allocator.free(result);

    // line_comment, newline, eof
    try testing.expectEqual(3, result.len);
    try testing.expectEqual(.line_comment, result[0].kind);
    try expectSlice(result[0], src, "// this is a comment");
}

test "whitespace tokens" {
    const src = "  \t  ";
    const result = try tokenize(testing.allocator, src);
    defer testing.allocator.free(result);

    // whitespace + eof
    try testing.expectEqual(2, result.len);
    try testing.expectEqual(.whitespace, result[0].kind);
}

test "newline token" {
    const src = "\n";
    const result = try tokenize(testing.allocator, src);
    defer testing.allocator.free(result);

    try testing.expectEqual(2, result.len);
    try testing.expectEqual(.newline, result[0].kind);
}

test "block comment" {
    const src =
        \\/* This is a comment */
    ;
    const result = try tokenize(testing.allocator, src);
    defer testing.allocator.free(result);

    try testing.expectEqual(2, result.len);
    try testing.expectEqual(.block_comment, result[0].kind);
}
