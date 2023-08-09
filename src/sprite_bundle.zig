const zrl = @import("init.zig");
const ztg = @import("zentig");

const Self = @This();

pub const is_component_bundle = true;

sprite: zrl.Sprite,
transform: ztg.base.Transform,

pub fn init(com: ztg.Commands, file_name: []const u8, pos: ztg.Vec3) !Self {
    return .{
        .sprite = try zrl.Sprite.init(com, file_name),
        .transform = ztg.base.Transform.fromPos(pos),
    };
}

const InitOptions = struct {
    transform: ztg.base.Transform.InitOptions = .{},
    sprite: zrl.Sprite.InitOptions = .{},
};

pub fn initWith(com: ztg.Commands, file_name: []const u8, options: InitOptions) !Self {
    return .{
        .sprite = try zrl.Sprite.initWith(com, file_name, options.sprite),
        .transform = ztg.base.Transform.initWith(options.transform),
    };
}

pub fn initAssert(com: ztg.Commands, file_name: []const u8, pos: ztg.Vec3) Self {
    return .{
        .sprite = zrl.Sprite.initAssert(com, file_name),
        .transform = ztg.base.Transform.fromPos(pos),
    };
}