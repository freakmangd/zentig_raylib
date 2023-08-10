const std = @import("std");
const ztg = @import("zentig");
const zrl = @import("zrl");

pub fn main() !void {
    zrl.InitWindow(800, 600, "Untitled");
    defer zrl.CloseWindow();

    zrl.SetTargetFPS(500);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var world = try World.init(alloc);
    defer world.deinit();

    try zrl.defaultLoop(world, .{});
}

pub const Input = ztg.input.Build(
    zrl.InputWrapper,
    .{},
    .{ .horiz, .vert },
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
    wb.addLoadSystems(load);
}

fn load(com: ztg.Commands, input: *Input) !void {
    _ = try com.newEntWithMany(zrl.Camera2dBundle.init());

    try input.addBindings(0, .{
        .axes = .{
            .horiz = &.{zrl.kbAxis(zrl.KEY_D, zrl.KEY_A)},
            .vert = &.{zrl.kbAxis(zrl.KEY_W, zrl.KEY_S)},
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

    fn ld_spawnPlayer(com: ztg.Commands) !void {
        _ = try zrl.util.newCenteredEnt(com, .{
            Player{},
            try zrl.SpriteBundle.initWith(com, "examples/smile.png", .{
                .transform = .{
                    .pos = ztg.vec3(zrl.GetScreenWidth(), zrl.GetScreenHeight(), 0).div(2),
                },
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
            if (@fabs(horiz) > 0.3 or @fabs(vert) > 0.3) {
                tr.translate(ztg.vec2(horiz, vert).mul(speed * time.dt).extend(0));
            }
        }
    }
};
