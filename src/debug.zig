const zrl = @import("init.zig");
const ztg = @import("zentig");

pub fn include(comptime wb: *ztg.WorldBuilder) void {
    wb.addSystemsToStage(.rl_draw_thru_cam, drawRectangles);
    wb.addComponents(&.{DebugRectangle});
}

pub const DebugRectangle = struct {
    color: zrl.rl.Color = zrl.rl.WHITE,
    size: ztg.Vec2 = ztg.Vec2.one,
    centered: bool = false,
};

pub fn drawRectangles(q: ztg.Query(.{ DebugRectangle, ztg.base.Transform })) void {
    for (q.items(0), q.items(1)) |dr, transform| {
        var pos = transform.getPos().flatten();
        const scale = transform.getScale();
        const render_size = dr.size.scale(scale.flatten());

        if (dr.centered) pos.subEql(render_size.div(2));
        zrl.rl.DrawRectangleV(pos.into(zrl.rl.Vector2), render_size.into(zrl.rl.Vector2), dr.color);
    }
}
