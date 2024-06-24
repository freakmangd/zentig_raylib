const std = @import("std");
const ztg = @import("zentig");
const zrl = @import("init.zig");
const rl = zrl.rl;

pub fn include(comptime wb: *ztg.WorldBuilder) void {
    wb.addComponents(&.{ rl.Camera2D, rl.Camera3D });
    wb.addStage(.rl_draw_thru_cam);
}

pub const Camera2dBundle = struct {
    pub const is_component_bundle = true;

    cam: rl.Camera2D = .{
        .offset = .{},
        .target = .{},
        .rotation = 0.0,
        .zoom = 1.0,
    },
};

pub const Camera3dBundle = struct {
    pub const is_component_bundle = true;

    cam: rl.Camera3D = .{
        .position = .{},
        .target = .{},
        .up = zrl.vec3up,
        .fovy = 90,
        .projection = 0,
    },
};
