const std = @import("std");
const ztg = @import("zentig");
const zrl = @import("zrl");
const rl = zrl.rl;

// Constructing the world must be done at comptime.
// `.init(...)` passes its arguments to `.include(...)`
const MyWorld = ztg.WorldBuilder.init(&.{
    ztg.base,
    zrl,
    @This(),
}).Build();

// entities with both a Sprite and Transform component will
// be drawn during the .rl_thru_cams stage, which is invoked with zrl.drawThroughCams
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
    _ = try com.newEntWith(zrl.Camera2dBundle.init());

    for (0..10) |_| {
        _ = try com.newEntWith(RlObject{
            zrl.Sprite.initAssert(com, "examples/smile.png", .{}),
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

pub fn pod_gui() void {
    rl.DrawText("Press space to randomize the sprite positions", 0, 0, 20, rl.WHITE);
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
        try world.runUpdateStages();

        rl.BeginDrawing();
        rl.ClearBackground(rl.BLACK);

        // .draw stage and drawThroughCams must be called between rl.BeginDrawing() and rl.EndDrawing()
        try zrl.drawThroughCams(&world);
        try world.runStage(.draw);

        rl.EndDrawing();

        world.cleanForNextFrame();
    }
}
