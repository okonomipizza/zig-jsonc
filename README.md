# zig-jsonc

A Zig library for parsing JSONC (JSON with Comments). Strips `//` line comments and `/* */` block comments from source, then delegates to `std.json.parseFromSlice()` — returning standard `std.json.Value` types.

## Features

- Strips single-line (`//`) and block (`/* */`) comments before parsing
- Returns `std.json.Parsed(T)` — fully compatible with Zig's standard library JSON types
- Thin wrapper around `std.json.parseFromSlice()`; no custom AST or parser

### Single-line Comments

```jsonc
{
    // This is a single-line comment
    "key": "value"
}
```

### Block Comments

```jsonc
{
  /*
     This is a
     block comment
  */
  "key": "value"
}
```

## Installation

```console
$ zig fetch --save git+https://github.com/okonomipizza/zig-jsonc 
```

Then add the following to `build.zig`

```zig
const zig_jsonc = b.dependencies("zig-jsonc", .{});
exe.root_module.addImport("jsonc", jsonpico.module("zig_jsonc"));
```

### How to use

Same interface as `std.json.parseFromSlice()` — specify the target type and parse options directly.
```zig
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
```

Retrieve a nested value by key path

```zig
test "get value by path" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const src =
        \\{
        \\ "user": {
        \\   "address": {
        \\     "city": "Tokyo"
        \\   }
        \\ }
        \\}
    ;


    var jsonc = Jsonc.init(src);
    defer jsonc.deinit();

    const parsed = try jsonc.parse(std.json.Value, allocator, .{});
    defer parsed.deinit();

    const city = try Jsonc.getValueByPath(parsed.value, &.{ "user", "address", "city" });

    try testing.expectEqualStrings("Tokyo", city.?.string);
}

const std = @import("std");
const Jsonc = @import("jsonc").Jsonc;
```

## License
MIT
