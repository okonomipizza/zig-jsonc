const std = @import("std");

pub const Jsonc = @import("jsonc.zig");
pub const JsoncError = @import("error.zig").JsoncError;
const tokenizer = @import("tokenizer.zig");
const parser = @import("parser.zig");

test {
    std.testing.refAllDecls(@This());
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

    var jsonc = Jsonc.init(src);
    defer jsonc.deinit();

    const parsed = try jsonc.parse(std.json.Value, allocator, .{});
    defer parsed.deinit();

    try testing.expect(parsed.value == .object);
    try testing.expectEqualStrings("value", parsed.value.object.get("key").?.string);
}

test "invalid line comment" {
    const allocator = testing.allocator;
    const src =
        \\ {
        \\  / This is a invalid line comment
        \\  "key": "value"
        \\ }
    ;

    var jsonc = Jsonc.init(src);
    defer jsonc.deinit();

    const result = jsonc.parse(std.json.Value, allocator, .{});
    try testing.expectError(error.InvalidJson, result);
}

test "array with line_comment" {
    const allocator = testing.allocator;
    const src =
        \\ [
        \\  // This is comment
        \\  1, 2, 3
        \\ ]
    ;

    var jsonc = Jsonc.init(src);
    defer jsonc.deinit();

    const parsed = try jsonc.parse(std.json.Value, allocator, .{});
    defer parsed.deinit();

    try testing.expect(parsed.value == .array);
    try testing.expectEqual(@as(i64, 1), parsed.value.array.items[0].integer);
    try testing.expectEqual(@as(i64, 2), parsed.value.array.items[1].integer);
    try testing.expectEqual(@as(i64, 3), parsed.value.array.items[2].integer);
}

test "invalid block comment" {
    const allocator = testing.allocator;
    const src =
        \\ {
        \\  /* This is comment
        \\     second line
        \\  *
        \\  "key": "value"
        \\ }
    ;

    var jsonc = Jsonc.init(src);
    defer jsonc.deinit();

    const result = jsonc.parse(std.json.Value, allocator, .{});
    try testing.expectError(JsoncError.InvalidComment, result);
}

test "array with block_comment" {
    const allocator = testing.allocator;
    const src =
        \\ [
        \\    /*
        \\       This is comment
        \\       second line
        \\    */
        \\  1, 2, 3
        \\ ]
    ;

    var jsonc = Jsonc.init(src);
    defer jsonc.deinit();

    const parsed = try jsonc.parse(std.json.Value, allocator, .{});
    defer parsed.deinit();

    try testing.expect(parsed.value == .array);
    try testing.expectEqual(@as(i64, 1), parsed.value.array.items[0].integer);
    try testing.expectEqual(@as(i64, 2), parsed.value.array.items[1].integer);
    try testing.expectEqual(@as(i64, 3), parsed.value.array.items[2].integer);
}
