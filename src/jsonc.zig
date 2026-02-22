pub const std = @import("std");
pub const Jsonc = @This();

original: []const u8,
arena: *std.heap.ArenaAllocator,

pub fn init(allocator: std.mem.Allocator, jsonc_slice: []const u8) !Jsonc {
    const arena = try allocator.create(std.heap.ArenaAllocator);
    errdefer arena.deinit();

    arena.* = std.heap.ArenaAllocator.init(allocator);

    return .{
        .original = jsonc_slice,
        .arena = arena,
    };
}

pub fn deinit(self: *Jsonc) void {
    const child_allocator = self.arena.child_allocator;
    self.arena.deinit();
    child_allocator.destroy(self.arena);
}
