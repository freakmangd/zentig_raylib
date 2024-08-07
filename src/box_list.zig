const std = @import("std");
const ztg = @import("zentig");
const zrl = @import("init.zig");
const rl = zrl.rl;

const Self = @This();

pub var draw_boxes: bool = false;

size: ztg.Vec2,
offset: ztg.Vec2 = .{},
collisions: std.ArrayListUnmanaged(ztg.Entity) = .{},

pub fn init(width: f32, height: f32) Self {
    return .{ .size = ztg.vec2(width, height) };
}

pub fn setCentered(self: *Self) void {
    self.offset = self.size.div(2).getNegated();
}

pub fn include(comptime wb: *ztg.WorldBuilder) void {
    wb.addComponents(&.{Self});
    wb.addLabel(.post_update, .zrl_check_cols, .{ .after = .gtr_update });
    wb.addSystems(.{
        .post_update = ztg.during(.zrl_check_cols, pou_checkCollisions),
        .draw = draw,
    });
}

fn rectFromBoxAndGtr(box: *const Self, gtr: *const ztg.base.GlobalTransform) rl.Rectangle {
    return zrl.rectangleV(
        gtr.getPos().flatten().add(box.offset),
        box.size.scale(gtr.getScale().flatten()),
    );
}

// this function is really bad but it works for testing
fn pou_checkCollisions(alloc: ztg.FrameAlloc, q: ztg.Query(.{ Self, ztg.Entity, ztg.base.GlobalTransform })) !void {
    for (q.items(0), q.items(1), q.items(2)) |cb, ent, gtr| {
        cb.collisions = .{};

        for (q.items(0), q.items(1), q.items(2)) |other, other_ent, other_gtr| {
            if (ent != other_ent and rl.CheckCollisionRecs(
                rectFromBoxAndGtr(cb, gtr),
                rectFromBoxAndGtr(other, other_gtr),
            )) {
                try cb.collisions.append(alloc[0], other_ent);
            }
        }
    }
}

fn draw(q: ztg.Query(.{ Self, ztg.base.GlobalTransform })) void {
    if (!draw_boxes) return;
    for (q.items(0), q.items(1)) |box, gtr| {
        rl.DrawRectangleLinesEx(rectFromBoxAndGtr(box, gtr), 3, rl.RED);
    }
}
