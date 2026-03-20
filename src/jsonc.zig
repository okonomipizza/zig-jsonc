const std = @import("std");
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

/// Retrieves a JSON value by traversing a path of keys (e.g. &.{"user", "address", "city"}).
/// Returns null if any key is not found, or an error if a non-object is encountered mid-path.
pub fn getValueByPath(root: std.json.Value, keys: []const []const u8) error{NotAnObject}!?std.json.Value {
    if (keys.len == 0) return root;
    if (root != .object) return error.NotAnObject;

    const next = root.object.get(keys[0]) orelse return null;

    if (keys.len == 1) return next;
    return getValueByPath(next, keys[1..]);
}

test "get value by path" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const json_str =
        \\{
        \\ "user": {
        \\   "address": {
        \\     "city": "Tokyo"
        \\   }
        \\ }
        \\}
    ;

    const parsed = try std.json.parseFromSlice(
        std.json.Value,
        allocator,
        json_str,
        .{},
    );
    defer parsed.deinit();

    const city = try getValueByPath(parsed.value, &.{ "user", "address", "city" });

    try testing.expectEqualStrings("Tokyo", city.?.string);
}

test "Null result" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const json_str =
        \\{
        \\ "user": {
        \\   "address": {
        \\     "city": "Tokyo"
        \\   }
        \\ }
        \\}
    ;

    const parsed = try std.json.parseFromSlice(
        std.json.Value,
        allocator,
        json_str,
        .{},
    );
    defer parsed.deinit();

    const maybe_town = try getValueByPath(parsed.value, &.{ "user", "address", "town" });

    try testing.expectEqual(null, maybe_town);
}
