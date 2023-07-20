const std = @import("std");
const ztg = @import("zentig");
const rl = @import("raylib");

pub usingnamespace @import("rl_input.zig");

pub const raylib = rl;
pub const Sprite = @import("rl_sprite.zig");
pub const Camera2dBundle = @import("rl_cam2d.zig").Camera2dBundle;

pub const log = std.log.scoped(.zentig_raylib);

pub fn defaultLoop(world: anytype, options: struct {
    clear_color: rl.Color = rl.BLACK,
}) !void {
    try world.runStage(.load);

    while (!rl.WindowShouldClose()) {
        try world.runStage(.update);

        rl.BeginDrawing();
        rl.ClearBackground(options.clear_color);
        try world.runStage(.draw);
        rl.EndDrawing();

        world.cleanForNextFrame();
    }
}

pub fn defaultLoopProfiled(world: anytype, profiler_writer: anytype, options: struct {
    clear_color: rl.Color = rl.BLACK,
}) !void {
    ztg.profiler.startSection("MAIN_LOOP load");
    try world.runStage(.load);
    ztg.profiler.endSection("MAIN_LOOP load");

    while (!rl.WindowShouldClose()) {
        defer ztg.profiler.report(profiler_writer, rl.GetFrameTime());

        ztg.profiler.startSection("MAIN_LOOP frame");
        defer ztg.profiler.endSection("MAIN_LOOP frame");

        ztg.profiler.startSection("MAIN_LOOP update");
        try world.runStage(.update);
        ztg.profiler.endSection("MAIN_LOOP update");

        ztg.profiler.startSection("MAIN_LOOP draw");
        rl.BeginDrawing();
        rl.ClearBackground(options.clear_color);
        try world.runStage(.draw);
        rl.EndDrawing();
        ztg.profiler.endSection("MAIN_LOOP draw");

        world.cleanForNextFrame();
    }
}

pub fn include(comptime wb: *ztg.WorldBuilder) void {
    wb.include(&.{ ztg.base, Sprite, Camera2dBundle });
    wb.addSystemsToStage(.update, .{ztg.before(.body, pru_time)});
}

fn pru_time(time: *ztg.base.Time) void {
    time.update(rl.GetFrameTime());
}
