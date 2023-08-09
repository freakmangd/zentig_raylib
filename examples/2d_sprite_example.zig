const std = @import("std");
const ztg = @import("zentig");
const rl = @import("raylib");
const zrl = @import("zrl");

// Constructing the world must be done at comptime.
// `.init(...)` passes its arguments to `.include(...)`
const MyWorld = ztg.WorldBuilder.init(&.{
    ztg.base,
    zrl,
    @This(),
}).Build();

// entities with both a Sprite and Transform component will
// be drawn during the .draw stage
const RlObject = struct {
    zrl.Sprite,
    ztg.base.Transform,
};

pub fn include(comptime wb: *ztg.WorldBuilder) void {
    wb.addSystems(.{
        .load = .{load},
        .update = .{update},
    });
}

pub fn load(com: ztg.Commands) !void {
    _ = try com.newEntWithMany(zrl.Camera2dBundle.init());

    for (0..10) |_| {
        _ = try com.newEntWithMany(RlObject{
            try zrl.Sprite.init(com, "examples/smile.png"),
            ztg.base.Transform.initWith(.{ .pos = ztg.vec3(rl.GetRandomValue(0, rl.GetScreenWidth()), rl.GetRandomValue(0, rl.GetScreenHeight()), 0.0) }),
        });
    }
}

pub fn update(q: ztg.Query(.{ztg.base.Transform})) void {
    if (rl.IsKeyPressed(rl.KEY_SPACE)) {
        for (q.items(0)) |tr| {
            tr.setPos(ztg.vec3(rl.GetRandomValue(0, rl.GetScreenWidth()), rl.GetRandomValue(0, rl.GetScreenHeight()), 0.0));
        }
    }
}

pub fn main() !void {
    // typical raylib-zig setup
    const screen_width = 800;
    const screen_height = 600;

    rl.InitWindow(screen_width, screen_height, "Untitled");
    defer rl.CloseWindow();

    rl.SetTargetFPS(60);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    var world = try MyWorld.init(alloc);
    defer world.deinit();

    try world.runStage(.load);

    while (!rl.WindowShouldClose()) {
        try world.runStage(.update);

        rl.BeginDrawing();
        rl.ClearBackground(rl.BLACK);

        // .draw stage must be called between rl.BeginDrawing() and rl.EndDrawing()
        try world.runStage(.draw);

        rl.EndDrawing();

        world.cleanForNextFrame();
    }
}
