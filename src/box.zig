const std = @import("std");
const ztg = @import("zentig");
const rl = @import("raylib");

const Self = @This();

pub var draw_boxes: bool = false;

size: ztg.Vec2,

offset: ztg.Vec2 = .{},
on_collide: ?*const fn (ztg.Commands, ztg.Entity, ztg.Entity) anyerror!void = null,

pub fn init(width: f32, height: f32) Self {
    return .{ .size = ztg.vec2(width, height) };
}

pub fn initWith(width: f32, height: f32, options: struct {
    offset: ztg.Vec2 = .{},
    on_collide: ?*const fn (ztg.Commands, ztg.Entity, ztg.Entity) anyerror!void = null,
}) Self {
    return .{
        .size = ztg.vec2(width, height),
        .offset = options.offset,
        .on_collide = options.on_collide,
    };
}

pub fn setCentered(self: *Self) void {
    self.offset = self.size.div(2).getNegated();
}

pub fn include(comptime wb: *ztg.WorldBuilder) void {
    wb.addLabel(.post_update, .zrl_check_cols, .{ .after = .gtr_update });
    wb.addComponents(&.{Self});
    wb.addSystems(.{
        .post_update = ztg.during(.zrl_check_cols, pou_checkCollisions),
        .draw = drawBoxes,
    });
}

fn rectFromBoxAndGtr(box: Self, gtr: ztg.base.GlobalTransform) rl.Rectangle {
    return rl.rectangleV(
        gtr.getPos().flatten().add(box.offset),
        box.size.scale(gtr.getScale().flatten()),
    );
}

fn pou_checkCollisions(com: ztg.Commands, q: ztg.Query(.{ Self, ztg.Entity, ztg.base.GlobalTransform })) !void {
    for (q.items(0), q.items(1), q.items(2)) |cb, ent, gtr| {
        if (cb.on_collide == null) continue;

        for (q.items(0), q.items(1), q.items(2)) |other, other_ent, other_gtr| {
            if (ent != other_ent and rl.CheckCollisionRecs(
                rectFromBoxAndGtr(cb.*, gtr.*),
                rectFromBoxAndGtr(other.*, other_gtr.*),
            )) {
                try cb.on_collide.?(com, ent, other_ent);
            }
        }
    }
}

fn drawBoxes(q: ztg.Query(.{ Self, ztg.base.GlobalTransform })) void {
    if (!draw_boxes) return;

    for (q.items(0), q.items(1)) |box, gtr| {
        rl.DrawRectangleLinesEx(rectFromBoxAndGtr(box.*, gtr.*), 3, rl.RED);
    }
}
