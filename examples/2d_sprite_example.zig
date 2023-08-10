const std = @import("std");
const ztg = @import("zentig");
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
        .load = load,
        .update = update,
        .draw = ztg.after(.body, pod_gui),
    });
}

pub fn load(com: ztg.Commands) !void {
    _ = try com.newEntWithMany(zrl.Camera2dBundle.init());

    for (0..10) |_| {
        _ = try com.newEntWithMany(RlObject{
            zrl.Sprite.initAssert(com, "examples/smile.png"),
            ztg.base.Transform.initWith(.{ .pos = ztg.vec3(zrl.GetRandomValue(0, zrl.GetScreenWidth()), zrl.GetRandomValue(0, zrl.GetScreenHeight()), 0.0) }),
        });
    }
}

pub fn update(q: ztg.Query(.{ztg.base.Transform})) void {
    if (zrl.IsKeyPressed(zrl.KEY_SPACE)) {
        for (q.items(0)) |tr| {
            tr.setPos(ztg.vec3(zrl.GetRandomValue(0, zrl.GetScreenWidth()), zrl.GetRandomValue(0, zrl.GetScreenHeight()), 0.0));
        }
    }
}

pub fn pod_gui() void {
    zrl.DrawText("Press space to randomize the sprite positions", 0, 0, 20, zrl.WHITE);
}

pub fn main() !void {
    // typical raylib-zig setup
    const screen_width = 800;
    const screen_height = 600;

    zrl.InitWindow(screen_width, screen_height, "Untitled");
    defer zrl.CloseWindow();

    zrl.SetTargetFPS(60);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    var world = try MyWorld.init(alloc);
    defer world.deinit();

    try world.runStage(.load);

    while (!zrl.WindowShouldClose()) {
        try world.runUpdateStages();

        zrl.BeginDrawing();
        zrl.ClearBackground(zrl.BLACK);

        // .draw stage must be called between rl.BeginDrawing() and rl.EndDrawing()
        try world.runStage(.draw);

        zrl.EndDrawing();

        world.cleanForNextFrame();
    }
}
