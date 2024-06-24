const std = @import("std");
const ztg = @import("zentig");
const zrl = @import("zrl");
const rl = zrl.rl;

pub fn main() !void {
    rl.InitWindow(800, 600, "Untitled");
    defer rl.CloseWindow();

    rl.SetTargetFPS(500);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var world = try World.init(alloc);
    defer world.deinit();

    try zrl.defaultLoop(&world, .{});
}

pub const Input = ztg.input.Build(
    zrl.input.wrapper,
    enum {},
    enum { horiz, vert },
    .{ .max_controllers = 1 },
);

pub const World = ztg.WorldBuilder.init(&.{
    ztg.base,
    zrl,
    zrl.physics,
    @This(),
    Input,
    Player,
}).Build();

pub fn include(comptime wb: *ztg.WorldBuilder) void {
    wb.addSystemsToStage(.load, load);
}

fn load(com: ztg.Commands, input: *Input) !void {
    _ = try com.newEntWith(zrl.Camera2dBundle{});

    try input.addBindings(0, .{
        .axes = .{
            .horiz = &.{zrl.input.kbAxis(rl.KEY_D, rl.KEY_A)},
            .vert = &.{zrl.input.kbAxis(rl.KEY_W, rl.KEY_S)},
        },
    });
}

const Player = struct {
    const speed = 40;

    pub fn include(comptime wb: *ztg.WorldBuilder) void {
        wb.addComponents(&.{Player});
        wb.addSystems(.{
            .load = ld_spawnPlayer,
            .update = up_playerUpdate,
        });
    }

    fn ld_spawnPlayer(com: ztg.Commands, assets: *zrl.Assets) !void {
        _ = try zrl.util.newCenteredEnt(com, .{
            Player{},
            try zrl.Sprite.Bundle.init(assets, "examples/smile.png", .{
                .pos = ztg.vec3(rl.GetScreenWidth(), rl.GetScreenHeight(), 0).div(2),
            }),
        });
    }

    fn up_playerUpdate(
        time: ztg.base.Time,
        inp: Input,
        q: ztg.QueryOpts(.{ztg.base.Transform}, .{ztg.With(Player)}),
    ) !void {
        const horiz = inp.getAxis(0, .horiz);
        const vert = -inp.getAxis(0, .vert);

        for (q.items(0)) |tr| {
            if (@abs(horiz) > 0.3 or @abs(vert) > 0.3) {
                tr.translate(ztg.vec2(horiz, vert).mul(speed * time.dt).extend(0));
            }
        }
    }
};
