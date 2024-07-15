const std = @import("std");
const builtin = @import("builtin");
const ztg = @import("zentig");

pub const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
    @cInclude("rlgl.h");
});

pub const input = @import("input.zig");
pub const debug = @import("debug.zig");
pub const AnimWrapper = @import("anim_wrapper.zig");

pub const Sprite = @import("sprite.zig");
pub const Assets = @import("assets.zig");

const cams = @import("cam.zig");
pub const Camera2dBundle = cams.Camera2dBundle;
pub const Camera3dBundle = cams.Camera3dBundle;

pub const log = std.log.scoped(.zentig_raylib);

pub fn include(comptime wb: *ztg.WorldBuilder) void {
    wb.include(&.{ ztg.base, cams, Sprite, Assets, debug });
    wb.addSystemsToStage(.pre_update, ztg.before(.body, pru_time));
}

pub const physics = struct {
    pub const ColBox = @import("box_list.zig");

    pub fn include(comptime wb: *ztg.WorldBuilder) void {
        wb.include(&.{ColBox});
    }
};

pub const util = struct {
    /// Creates an entity with the specified components,
    /// centers it, and returns the handle to the entity
    pub fn newCenteredEnt(com: ztg.Commands, components: anytype) !ztg.EntityHandle {
        const ent = try com.newEntWith(components);
        centerEntity(com, ent.ent);
        return ent;
    }

    /// Creates a child entity parented to `parent` with the specified components,
    /// centers it, and returns the handle to the entity
    pub fn newCenteredChild(com: ztg.Commands, parent: ztg.Entity, components: anytype) !ztg.EntityHandle {
        const child = try com.newEntWith(components);
        try child.setParent(parent);
        centerEntity(com, child.ent);
        return child;
    }

    /// Adjusts sprite and collision box offsets so that
    /// they are centered around the entity position
    pub fn centerEntity(com: ztg.Commands, ent: ztg.Entity) void {
        if (com.getComponentPtr(ent, Sprite)) |spr| spr.setCentered();
        if (com.hasIncluded(physics)) if (com.getComponentPtr(ent, physics.ColBox)) |box| box.setCentered();
    }
};

pub fn drawThroughCams(world: anytype) !void {
    if (comptime @typeInfo(@TypeOf(world)) != .Pointer) @compileError(std.fmt.comptimePrint("Expected a mutable pointer to your world. Got `{s}`.", .{@typeName(@TypeOf(world))}));
    var q = try world.query(world.frame_alloc, ztg.Query(.{rl.Camera2D}));
    defer q.deinit(world.frame_alloc);

    for (q.items(0)) |cam| {
        rl.BeginMode2D(cam.*);
        defer rl.EndMode2D();
        try world.runStage(.rl_draw_thru_cam);
    }
}

pub fn defaultLoop(world: anytype, comptime options: struct {
    clear_color: rl.Color = rl.BLACK,
    use_profiler: bool = false,
}) !void {
    if (comptime @typeInfo(@TypeOf(world)) != .Pointer) @compileError(std.fmt.comptimePrint("Expected a mutable pointer to your world. Got `{s}`.", .{@typeName(@TypeOf(world))}));

    var load_sec = optionalProfiling(options.use_profiler, "MAIN_LOOP load");
    try world.runStage(.load);
    load_sec.end();

    const stderr_writer = std.io.getStdErr().writer();

    while (!rl.WindowShouldClose()) {
        defer if (comptime options.use_profiler) ztg.profiler.reportTimed(stderr_writer, 1, rl.GetFrameTime());

        var frame_sec = optionalProfiling(options.use_profiler, "MAIN_LOOP frame");
        defer frame_sec.end();

        var update_sec = optionalProfiling(options.use_profiler, "MAIN_LOOP update");
        try world.runUpdateStages();
        update_sec.end();

        var draw_sec = optionalProfiling(options.use_profiler, "MAIN_LOOP draw");
        rl.BeginDrawing();
        rl.ClearBackground(options.clear_color);
        try drawThroughCams(world);
        try world.runStage(.draw);
        rl.EndDrawing();
        draw_sec.end();

        world.cleanForNextFrame();
    }
}

fn optionalProfiling(comptime use_profiler: bool, comptime name: []const u8) if (use_profiler) *ztg.profiler.ProfilerSection else struct {
    fn end(_: @This()) void {}
} {
    if (comptime use_profiler)
        return ztg.profiler.startSection(name)
    else
        return undefined;
}

fn pru_time(time: *ztg.base.Time) void {
    time.update(rl.GetFrameTime());
}

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

pub const vec2up: rl.Vector2 = .{ .x = 0, .y = 1 };
pub const vec3up: rl.Vector3 = .{ .x = 0, .y = 1, .z = 0 };
pub const vec4up: rl.Vector4 = .{ .x = 0, .y = 1, .z = 0, .w = 0 };

pub inline fn vec2(x: f32, y: f32) rl.Vector2 {
    return .{ .x = x, .y = y };
}

pub inline fn vec2splat(v: f32) rl.Vector2 {
    return .{ .x = v, .y = v };
}

pub inline fn vec3(x: anytype, y: anytype, z: anytype) rl.Vector3 {
    return .{
        .x = if (@typeInfo(@TypeOf(x)) == .Int) @floatFromInt(x) else x,
        .y = if (@typeInfo(@TypeOf(y)) == .Int) @floatFromInt(y) else y,
        .z = if (@typeInfo(@TypeOf(z)) == .Int) @floatFromInt(z) else z,
    };
}

fn vectorLen(comptime V: type) usize {
    return switch (V) {
        rl.Vector2 => 2,
        rl.Vector3 => 3,
        rl.Vector4 => 4,
        else => @compileError("Type " ++ @typeName(V) ++ " not supported"),
    };
}

pub fn VectorOfLen(comptime len: usize) ?type {
    return switch (len) {
        2 => rl.Vector2,
        3 => rl.Vector3,
        4 => rl.Vector4,
        else => null,
    };
}

pub inline fn toSimd(v: anytype) @Vector(vectorLen(@TypeOf(v)), f32) {
    return @bitCast(v);
}

pub inline fn fromSimd(v: @Vector(3, f32)) rl.Vector3 {
    return @bitCast(v);
}

pub inline fn toVec(v: anytype) ztg.math.VectorOfLen(vectorLen(v)).? {
    return @bitCast(v);
}

pub inline fn fromVec(v: anytype) VectorOfLen(@typeInfo(@TypeOf(v)).Struct.fields.len).? {
    return @bitCast(v);
}

pub inline fn vec3splat(v: f32) rl.Vector3 {
    return .{ .x = v, .y = v, .z = v };
}

pub inline fn vec4(x: f32, y: f32, z: f32, w: f32) rl.Vector4 {
    return .{ .x = x, .y = y, .z = z, .w = w };
}

pub inline fn vec4splat(v: f32) rl.Vector4 {
    return .{ .x = v, .y = v, .z = v, .w = v };
}

pub inline fn rectangle(x: f32, y: f32, width: f32, height: f32) rl.Rectangle {
    return .{ .x = x, .y = y, .width = width, .height = height };
}

pub inline fn rectangleV(pos: anytype, size: anytype) rl.Rectangle {
    return .{ .x = pos.x, .y = pos.y, .width = size.x, .height = size.y };
}
