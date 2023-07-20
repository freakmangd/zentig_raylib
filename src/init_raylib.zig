pub usingnamespace @cImport({
    @cInclude("raylib.h");
    @cInclude("rlgl.h");
});

const rl = @This();

pub fn vec2(x: f32, y: f32) rl.Vector2 {
    return .{ .x = x, .y = y };
}

pub fn vec2splat(v: f32) rl.Vector2 {
    return .{ .x = v, .y = v };
}

pub fn vec2zero() rl.Vector2 {
    return .{ .x = 0, .y = 0 };
}

pub fn vec3(x: f32, y: f32, z: f32) rl.Vector3 {
    return .{ .x = x, .y = y, .z = z };
}

pub fn vec3splat(v: f32) rl.Vector3 {
    return .{ .x = v, .y = v, .z = v };
}

pub fn vec3zero() rl.Vector3 {
    return .{ .x = 0, .y = 0, .z = 0 };
}

pub fn vec4(x: f32, y: f32, z: f32, w: f32) rl.Vector4 {
    return .{ .x = x, .y = y, .z = z, .w = w };
}

pub fn vec4splat(v: f32) rl.Vector4 {
    return .{ .x = v, .y = v, .z = v, .w = v };
}

pub fn vec4zero() rl.Vector4 {
    return .{ .x = 0, .y = 0, .z = 0, .w = 0 };
}

pub fn rectangle(x: f32, y: f32, width: f32, height: f32) rl.Rectangle {
    return .{ .x = x, .y = y, .width = width, .height = height };
}
