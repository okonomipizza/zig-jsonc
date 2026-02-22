const std = @import("std");
const Io = std.Io;
pub const Jsonc = @import("jsonc.zig");
pub const tokenizer = @import("tokenizer.zig");

/// This is a documentation comment to explain the `printAnotherMessage` function below.
///
/// Accepting an `Io.Writer` instance is a handy way to write reusable code.
pub fn printAnotherMessage(writer: *Io.Writer) Io.Writer.Error!void {
    try writer.print("Run `zig build test` to run the tests.\n", .{});
}

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try std.testing.expect(add(3, 7) == 10);
}

test "Jsonc init/deinit" {
    const text = "Hello world!";
    const allocator = std.testing.allocator;
    var jsonc = try Jsonc.init(allocator, text);
    defer jsonc.deinit();
}

test {
    std.testing.refAllDecls(@This());
}
