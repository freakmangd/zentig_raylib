const std = @import("std");
const ztg = @import("zentig");
const zrl = @import("init.zig");
const rl = zrl.rl;

const Sprite = @This();

tex: rl.Texture2D = std.mem.zeroInit(zrl.rl.Texture, .{}),
source: rl.Rectangle = zrl.rectangle(0, 0, 0, 0),

color: rl.Color = rl.WHITE,
pivot: ztg.Vec2 = .{},
order: i32 = 0,

pub const InitOptions = struct {
    color: rl.Color = rl.WHITE,
    pivot: ztg.Vec2 = .{},
    source: ?rl.Rectangle = null,
    order: i32 = 0,
};

/// Checks for missing files and caches textures by file_name
pub fn init(assets: *zrl.Assets, file_name: [:0]const u8) !Sprite {
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

pub fn initWith(assets: *zrl.Assets, file_name: [:0]const u8, options: InitOptions) !Sprite {
    var self = try init(assets, file_name);
    self.pivot = options.pivot;
    self.color = options.color;
    self.order = options.order;
    if (options.source) |src| self.source = src;
    return self;
}

/// Asserts that the file exists and that there is no OOM error, panics otherwise
pub fn initAssert(assets: *zrl.Assets, file_name: [:0]const u8, options: InitOptions) Sprite {
    return initWith(assets, file_name, options) catch |err| switch (err) {
        error.FileNotFound => std.debug.panic("Could not find file {s}", .{file_name}),
        error.OutOfMemory => std.debug.panic("OOM error for sprite texture index", .{}),
    };
}

pub fn emptyWith(options: InitOptions) Sprite {
    return .{
        .tex = std.mem.zeroInit(zrl.rl.Texture, .{}),
        .source = zrl.rectangle(0, 0, 0, 0),
        .pivot = options.pivot,
        .color = options.color,
        .order = options.order,
    };
}

pub fn setSource(self: *Sprite, x: f32, y: f32, w: f32, h: f32) void {
    self.source = .{ .x = x, .y = y, .width = w, .height = h };
}

pub fn setCentered(self: *Sprite) void {
    self.pivot = ztg.vec2(0.5, 0.5);
}

pub fn setFlippedHoriz(self: *Sprite, flip: bool) void {
    if ((flip == true and self.source.width > 0) or (flip == false and self.source.width < 0)) {
        self.flipHorizontal();
    }
}

pub fn flipHorizontal(self: *Sprite) void {
    self.source.width *= -1;
}

pub fn setFlippedVert(self: *Sprite, flip: bool) void {
    if ((flip == true and self.source.height > 0) or (flip == false and self.source.height < 0)) {
        self.flipVertical();
    }
}

pub fn flipVertical(self: *Sprite) void {
    self.source.height *= -1;
}

pub const Bundle = struct {
    pub const is_component_bundle = true;

    sprite: zrl.Sprite = .{},
    transform: ztg.base.Transform = .{},

    pub fn init(assets: *zrl.Assets, file_name: [:0]const u8, options: BundleInitOptions) !Bundle {
        return .{
            .sprite = try zrl.Sprite.initWith(assets, file_name, .{
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

    pub fn initAssert(assets: *zrl.Assets, file_name: [:0]const u8, options: BundleInitOptions) Bundle {
        return .{
            .sprite = zrl.Sprite.initAssert(assets, file_name, .{
                .color = options.color,
                .pivot = options.pivot,
                .source = options.source,
                .order = options.order,
            }),
            .transform = ztg.base.Transform.initWith(.{
                .pos = options.pos,
                .rot = options.rot,
                .scale = options.scale,
            }),
        };
    }

    pub fn emptyWith(options: BundleInitOptions) Bundle {
        return .{
            .sprite = zrl.Sprite.emptyWith(.{
                .pivot = options.pivot,
                .order = options.order,
                .source = options.source,
                .color = options.color,
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
        .rl_draw_thru_cam = .{dr_sprites},
    });
}

const use_matrix = true;
fn dr_sprites(query: ztg.Query(.{
    Sprite,
    ztg.base.GlobalTransform,
    ?ztg.base.Active,
})) void {
    const sprites = query.items(0);
    std.mem.sortUnstable(*Sprite, sprites, {}, struct {
        fn f(_: void, a: *Sprite, b: *Sprite) bool {
            return a.order < b.order;
        }
    }.f);

    for (sprites, query.items(1), query.items(2)) |spr, gtr, active| {
        if (active) |a| if (!a[0]) continue;

        rl.rlPushMatrix();

        if (comptime use_matrix) {
            rl.rlMultMatrixf(&ztg.zmath.matToArr(gtr.basis));

            const pivot_scaled = spr.pivot.intoSimd() * @Vector(2, f32){ @abs(spr.source.width), @abs(spr.source.height) };
            rl.rlTranslatef(-pivot_scaled[0], -pivot_scaled[1], 0);
        } else {
            const pos = gtr.getPos();
            const rot = gtr.getRot().toEulerAngles();
            const scale = gtr.getScale();

            rl.rlTranslatef(pos.x, pos.y, pos.z);

            rl.rlRotatef(std.math.radiansToDegrees(f32, rot.x), 1, 0, 0);
            rl.rlRotatef(std.math.radiansToDegrees(f32, rot.y), 0, 1, 0);
            rl.rlRotatef(std.math.radiansToDegrees(f32, rot.z), 0, 0, 1);
            rl.rlScalef(scale.x, scale.y, scale.z);

            const pivot_scaled = spr.pivot.intoSimd() * @Vector(2, f32){ spr.source.width, spr.source.height };
            rl.rlTranslatef(-pivot_scaled[0], -pivot_scaled[1], 0);
        }

        rl.DrawTextureRec(spr.tex, spr.source, .{}, spr.color);

        rl.rlPopMatrix();
    }
}
