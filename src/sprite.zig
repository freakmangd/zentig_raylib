const std = @import("std");
const rl = @import("raylib");
const ztg = @import("zentig");
const zrl = @import("init.zig");

const Sprite = @This();

tex: rl.Texture2D,
color: rl.Color = rl.WHITE,
pivot: ztg.Vec2 = .{},
source: rl.Rectangle,

pub const InitOptions = struct {
    color: rl.Color = rl.WHITE,
    pivot: ztg.Vec2 = .{},
    source: ?rl.Rectangle = null,
};

/// Checks for missing files and caches textures by file_name
pub fn init(com: ztg.Commands, file_name: [:0]const u8) !Sprite {
    var assets = com.getResPtr(zrl.Assets);
    const tex = try assets.texture(file_name);

    return .{
        .tex = tex,
        .source = rl.Rectangle{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(tex.width),
            .height = @floatFromInt(tex.height),
        },
    };
}

pub fn initWith(com: ztg.Commands, file_name: [:0]const u8, options: InitOptions) !Sprite {
    var self = try init(com, file_name);
    self.pivot = options.pivot;
    self.color = options.color;
    if (options.source) |src| self.source = src;
    return self;
}

/// Asserts that the file exists and that there is no OOM error, panics otherwise
pub fn initAssert(com: ztg.Commands, file_name: [:0]const u8, options: InitOptions) Sprite {
    return initWith(com, file_name, options) catch |err| switch (err) {
        error.FileNotFound => std.debug.panic("Could not find file {s}", .{file_name}),
        error.OutOfMemory => std.debug.panic("OOM error for sprite texture index", .{}),
    };
}

pub fn setSource(self: *Sprite, x: f32, y: f32, w: f32, h: f32) void {
    self.source = .{ .x = x, .y = y, .width = w, .height = h };
}

pub fn setCentered(self: *Sprite) void {
    self.pivot = ztg.vec2(0.5, 0.5);
}

pub const Bundle = struct {
    pub const is_component_bundle = true;

    sprite: zrl.Sprite,
    transform: ztg.base.Transform,

    pub fn init(com: ztg.Commands, file_name: [:0]const u8, options: BundleInitOptions) !Bundle {
        return .{
            .sprite = try zrl.Sprite.initWith(com, file_name, .{
                .color = options.color,
                .pivot = options.pivot,
                .source = options.source,
            }),
            .transform = ztg.base.Transform.initWith(.{
                .pos = options.pos,
                .rot = options.rot,
                .scale = options.scale,
            }),
        };
    }

    pub fn initAssert(com: ztg.Commands, file_name: [:0]const u8, options: BundleInitOptions) Bundle {
        return .{
            .sprite = zrl.Sprite.initAssert(com, file_name, .{
                .color = options.color,
                .pivot = options.pivot,
                .source = options.source,
            }),
            .transform = ztg.base.Transform.initWith(.{
                .pos = options.pos,
                .rot = options.rot,
                .scale = options.scale,
            }),
        };
    }

    const BundleInitOptions = ztg.meta.CombineStructTypes(&.{ ztg.base.Transform.InitOptions, zrl.Sprite.InitOptions });
    //        transform: ztg.base.Transform.InitOptions = .{},
    //        sprite: zrl.Sprite.InitOptions = .{},
    //    };
};

pub fn include(comptime wb: *ztg.WorldBuilder) void {
    wb.addComponents(&.{Sprite});
    wb.addSystems(.{
        .draw = .{dr_sprites},
    });
}

const use_matrix = true;
fn dr_sprites(cameras: ztg.Query(.{rl.Camera2D}), query: ztg.Query(.{ Sprite, ztg.base.GlobalTransform })) void {
    for (cameras.items(0)) |cam| {
        rl.BeginMode2D(cam.*);

        for (query.items(0), query.items(1)) |spr, gtr| {
            rl.rlPushMatrix();

            if (comptime use_matrix) {
                rl.rlMultMatrixf(&ztg.zmath.matToArr(gtr.basis));

                const pivot_scaled = spr.pivot.intoSimd() * @Vector(2, f32){ spr.source.width, spr.source.height };
                rl.rlTranslatef(-pivot_scaled[0], -pivot_scaled[1], 0);
            } else {
                const pos = gtr.getPos();
                const rot = gtr.getRot();
                const scale = gtr.getScale();

                rl.rlTranslatef(pos.x, pos.y, pos.z);

                rl.rlRotatef(std.math.radiansToDegrees(f32, rot.x), 1, 0, 0);
                rl.rlRotatef(std.math.radiansToDegrees(f32, rot.y), 0, 1, 0);
                rl.rlRotatef(std.math.radiansToDegrees(f32, rot.z), 0, 0, 1);
                rl.rlScalef(scale.x, scale.y, scale.z);

                const pivot_scaled = spr.pivot.intoSimd() * @Vector(3, f32){ spr.source.width, spr.source.height, 1 };
                rl.rlTranslatef(-pivot_scaled[0], -pivot_scaled[1], -pivot_scaled[2]);
            }

            rl.DrawTextureRec(spr.tex, spr.source, rl.vec2zero(), spr.color);

            rl.rlPopMatrix();
        }

        rl.EndMode2D();
    }
}
