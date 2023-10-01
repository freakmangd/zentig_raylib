const std = @import("std");
const ztg = @import("zentig");

pub const rl = @import("raylib");
pub usingnamespace @import("input.zig");
pub const AnimWrapper = @import("anim_wrapper.zig");

pub const Sprite = @import("sprite.zig");
pub const Camera2dBundle = @import("cam2d.zig").Camera2dBundle;
pub const Assets = @import("assets.zig");

pub fn include(comptime wb: *ztg.WorldBuilder) void {
    wb.include(&.{ ztg.base, Camera2dBundle, Sprite, Assets });
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

pub const log = std.log.scoped(.zentig_raylib);

pub fn drawThroughCams(world: anytype) !void {
    if (comptime !std.meta.trait.isSingleItemPtr(@TypeOf(world))) @compileError(std.fmt.comptimePrint("Expected a mutable pointer to your world. Got `{s}`.", .{@typeName(@TypeOf(world))}));
    var q = try world.query(world.frame_alloc, ztg.Query(.{rl.Camera2D}));

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
    if (comptime !std.meta.trait.isSingleItemPtr(@TypeOf(world))) @compileError(std.fmt.comptimePrint("Expected a mutable pointer to your world. Got `{s}`.", .{@typeName(@TypeOf(world))}));

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
