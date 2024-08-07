const std = @import("std");
const ztg = @import("zentig");
const zrl = @import("init.zig");
const rl = zrl.rl;

pub const QueryType = zrl.Sprite;
pub const LoadImageCtx = *zrl.Assets;

pub const Image = rl.Texture;
pub const ImageRect = rl.Rectangle;

pub fn loadImage(assets: *zrl.Assets, path: [:0]const u8) !Image {
    return assets.texture(path);
}

pub fn onFrame(
    img: Image,
    slice_method: ztg.anim.ImageSliceMethod,
    slice_indexes: @Vector(2, usize),
    query: *zrl.Sprite,
) void {
    const rect = switch (slice_method) {
        .none => zrl.rectangle(0, 0, @floatFromInt(img.width), @floatFromInt(img.height)),
        .auto_slice => |as| zrl.rectangle(
            @floatFromInt(as.width * slice_indexes[0]),
            @floatFromInt(as.height * slice_indexes[1]),
            @floatFromInt(as.width),
            @floatFromInt(as.height),
        ),
    };
    query.source = rect;
    query.tex = img;
}
