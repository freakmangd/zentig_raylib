const std = @import("std");
const rl = @import("raylib");
const ztg = @import("zentig");
const zmath = @import("zmath");

const Sprite = @This();

tex: rl.Texture2D,
color: rl.Color = rl.WHITE,
pivot: ztg.Vec3 = .{ .x = 0.5, .y = 0.5 },
source: rl.Rectangle,

const TexIndex = struct { std.StringHashMap(rl.Texture2D) };

/// Checks for missing files and caches textures by file_name
pub fn init(com: ztg.Commands, file_name: []const u8) !Sprite {
    var tex_index = com.getResPtr(TexIndex);

    const tex = blk: {
        if (tex_index[0].get(file_name)) |tex| {
            break :blk tex;
        } else {
            const tex = rl.LoadTexture(file_name.ptr);
            if (tex.id == 0) return error.FileNotFound;

            try tex_index[0].put(file_name, tex);
            break :blk tex;
        }
    };

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

pub fn initWith(com: ztg.Commands, file_name: []const u8, options: struct {
    color: rl.Color = rl.WHITE,
    pivot: ztg.Vec3 = .{ .x = 0.5, .y = 0.5 },
    source: ?rl.Rectangle = null,
}) !Sprite {
    var self = try init(com, file_name);
    self.pivot = options.pivot;
    self.color = options.color;
    if (options.source) |src| self.source = src;
    return self;
}

pub inline fn setSource(self: *Sprite, x: f32, y: f32, w: f32, h: f32) void {
    self.source = .{ .x = x, .y = y, .width = w, .height = h };
}

pub fn include(comptime wb: *ztg.WorldBuilder) void {
    wb.addComponents(&.{Sprite});
    wb.addResource(TexIndex, .{undefined});
    wb.addSystems(.{
        .init = .{ini_TexIndex},
        .draw = .{dr_sprites},
        .deinit = .{dei_TexIndex},
    });
}

fn ini_TexIndex(alloc: std.mem.Allocator, tex_index: *TexIndex) void {
    tex_index[0] = std.StringHashMap(rl.Texture2D).init(alloc);
}

fn dei_TexIndex(tex_index: *TexIndex) void {
    var tex_iter = tex_index[0].valueIterator();
    while (tex_iter.next()) |tex| {
        rl.UnloadTexture(tex.*);
    }
    tex_index[0].deinit();
}

const use_matrix = true;
fn dr_sprites(cameras: ztg.Query(.{rl.Camera2D}), query: ztg.Query(.{ Sprite, ztg.base.Transform })) void {
    for (cameras.items(0)) |cam| {
        rl.BeginMode2D(cam.*);

        for (query.items(0), query.items(1)) |spr, trn| {
            rl.rlPushMatrix();

            if (comptime use_matrix) {
                rl.rlMultMatrixf(&zmath.matToArr(trn.getGlobalMatrix()));

                const pivot_scaled = spr.pivot.intoSimd() * @Vector(3, f32){ spr.source.width, spr.source.height, 1 };
                rl.rlTranslatef(-pivot_scaled[0], -pivot_scaled[1], -pivot_scaled[2]);
            } else {
                const pos = trn.getPos();
                const rot = trn.getRot();
                const scale = trn.getScale();

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
