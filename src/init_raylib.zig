pub usingnamespace @cImport({
    @cInclude("raylib.h");
    @cInclude("rlgl.h");
});

const rl = @This();

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
