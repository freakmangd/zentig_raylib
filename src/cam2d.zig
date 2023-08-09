const std = @import("std");
const ztg = @import("zentig");
const rl = @import("raylib");
const zrl = @import("init.zig");

pub const Camera2dBundle = struct {
    cam: rl.Camera2D,

    pub fn init() Camera2dBundle {
        return .{
            .cam = rl.Camera2D{
                .offset = rl.vec2(0, 0),
                .target = rl.vec2(0, 0),
                .rotation = 0.0,
                .zoom = 1.0,
            },
        };
    }

    pub fn include(comptime wb: *ztg.WorldBuilder) void {
        wb.addComponents(&.{rl.Camera2D});
        wb.addSystemsToStage(.load, ztg.after(.body, pol_checkCams));
    }

    fn pol_checkCams(cameras: ztg.Query(.{rl.Camera2D})) void {
        if (cameras.len == 0) {
            zrl.log.warn("No cameras detected after init stage. Try adding one with `commands.giveEntMany(ent, zrl.Camera2dBundle.init())`", .{});
        }
    }
};
