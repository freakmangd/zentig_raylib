const std = @import("std");
pub usingnamespace @cImport({
    @cInclude("raylib.h");
    @cInclude("rlgl.h");
});

const rl = @This();

pub inline fn drawTextBuf(comptime buf_size: usize, comptime fmt: []const u8, args: anytype, x: anytype, y: anytype, font_size: c_int, _color: rl.Color) !void {
    var buf: [buf_size]u8 = undefined;
    const str = try std.fmt.bufPrintZ(&buf, fmt, args);
    rl.DrawText(
        str.ptr,
        if (comptime @typeInfo(@TypeOf(x)) == .Float) @intFromFloat(x) else x,
        if (comptime @typeInfo(@TypeOf(y)) == .Float) @intFromFloat(y) else y,
        font_size,
        _color,
    );
}

pub inline fn drawTextExBuf(comptime buf_size: usize, comptime fmt: []const u8, args: anytype, font: rl.Font, position: rl.Vector2, font_size: c_int, spacing: c_int, _color: rl.Color) !void {
    var buf: [buf_size]u8 = undefined;
    const str = try std.fmt.bufPrintZ(&buf, fmt, args);
    rl.DrawTextEx(font, str.ptr, position, font_size, spacing, _color);
}

pub inline fn vec2(x: f32, y: f32) rl.Vector2 {
    return .{ .x = x, .y = y };
}

pub inline fn vec2splat(v: f32) rl.Vector2 {
    return .{ .x = v, .y = v };
}

pub inline fn vec2zero() rl.Vector2 {
    return .{ .x = 0, .y = 0 };
}

pub inline fn vec3(x: f32, y: f32, z: f32) rl.Vector3 {
    return .{ .x = x, .y = y, .z = z };
}

pub inline fn vec3splat(v: f32) rl.Vector3 {
    return .{ .x = v, .y = v, .z = v };
}

pub inline fn vec3zero() rl.Vector3 {
    return .{ .x = 0, .y = 0, .z = 0 };
}

pub inline fn vec4(x: f32, y: f32, z: f32, w: f32) rl.Vector4 {
    return .{ .x = x, .y = y, .z = z, .w = w };
}

pub inline fn vec4splat(v: f32) rl.Vector4 {
    return .{ .x = v, .y = v, .z = v, .w = v };
}

pub inline fn vec4zero() rl.Vector4 {
    return .{ .x = 0, .y = 0, .z = 0, .w = 0 };
}

pub inline fn rectangle(x: f32, y: f32, width: f32, height: f32) rl.Rectangle {
    return .{ .x = x, .y = y, .width = width, .height = height };
}

pub inline fn rectangleV(pos: anytype, size: anytype) rl.Rectangle {
    return .{ .x = pos.x, .y = pos.y, .width = size.x, .height = size.y };
}

pub inline fn color(r: u8, g: u8, b: u8) rl.Color {
    return colorA(r, g, b, 255);
}

pub inline fn colorA(r: u8, g: u8, b: u8, a: u8) rl.Color {
    return rl.Color{ .r = r, .g = g, .b = b, .a = a };
}

pub inline fn colorLerp(a: rl.Color, b: rl.Color, t: f32) rl.Color {
    const ar: f32 = @floatFromInt(a.r);
    const ag: f32 = @floatFromInt(a.g);
    const ab: f32 = @floatFromInt(a.b);
    const aa: f32 = @floatFromInt(a.a);
    const br: f32 = @floatFromInt(b.r);
    const bg: f32 = @floatFromInt(b.g);
    const bb: f32 = @floatFromInt(b.b);
    const ba: f32 = @floatFromInt(b.a);
    return .{
        .r = @intFromFloat(std.math.lerp(ar, br, t)),
        .g = @intFromFloat(std.math.lerp(ag, bg, t)),
        .b = @intFromFloat(std.math.lerp(ab, bb, t)),
        .a = @intFromFloat(std.math.lerp(aa, ba, t)),
    };
}
