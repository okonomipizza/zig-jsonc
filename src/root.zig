const std = @import("std");

pub const Jsonc = @import("jsonc.zig");
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

test "object key-value pair with block_comment" {
    const allocator = testing.allocator;
    const src =
        \\ {
        \\  /* This is comment
        \\     second line
        \\  */
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
