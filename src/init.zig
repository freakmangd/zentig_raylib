const std = @import("std");
const ztg = @import("zentig");
const rl = @import("raylib");

pub usingnamespace @import("input.zig");
pub usingnamespace rl;

pub const Sprite = @import("sprite.zig");
pub const SpriteBundle = @import("sprite_bundle.zig");
pub const Camera2dBundle = @import("cam2d.zig").Camera2dBundle;

pub fn include(comptime wb: *ztg.WorldBuilder) void {
    wb.include(&.{ ztg.base, Sprite, Camera2dBundle });
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
        const ent = try com.newEntWithMany(components);
        centerEntity(com, ent.ent);
        return ent;
    }

    /// Creates a child entity parented to `parent` with the specified components,
    /// centers it, and returns the handle to the entity
    pub fn newCenteredChild(com: ztg.Commands, parent: ztg.Entity, components: anytype) !ztg.EntityHandle {
        const child = try com.newEntWithMany(components);
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

pub const log = std.log.scoped(.zentig_raylib);

pub fn defaultLoop(world: anytype, options: struct {
    clear_color: rl.Color = rl.BLACK,
}) !void {
    try world.runStage(.load);

    while (!rl.WindowShouldClose()) {
        try world.runUpdateStages();

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
    var load_sec = ztg.profiler.startSection("MAIN_LOOP load");
    try world.runStage(.load);
    load_sec.end();

    while (!rl.WindowShouldClose()) {
        defer ztg.profiler.report(profiler_writer, rl.GetFrameTime());

        var frame_sec = ztg.profiler.startSection("MAIN_LOOP frame");
        defer frame_sec.end();

        var update_sec = ztg.profiler.startSection("MAIN_LOOP update");
        try world.runUpdateStages();
        update_sec.end();

        var draw_sec = ztg.profiler.startSection("MAIN_LOOP draw");
        rl.BeginDrawing();
        rl.ClearBackground(options.clear_color);
        try world.runStage(.draw);
        rl.EndDrawing();
        draw_sec.end();

        world.cleanForNextFrame();
    }
}

fn pru_time(time: *ztg.base.Time) void {
    time.update(rl.GetFrameTime());
}
