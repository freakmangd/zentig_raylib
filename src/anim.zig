const std = @import("std");
const ztg = @import("zentig");
const rl = @import("raylib");

const Self = @This();

state: ztg.StateMachine,
anims: []Animation,

pub const Animation = struct {
    alloc: std.mem.Allocator,
    frames: std.MultiArrayList(Frame) = .{},

    frames_elapsed: usize = 0,
    cur_frame: usize = 0, // <- this value will be <= frame because frames can be held

    frame_start: usize = 0, // the frame the current Frame started on

    frame_time: f32 = 0.0,
    frames_per_sec: f32 = 30,
    use_realtime: bool = false,

    const TimedFrame = struct {
        frame: Frame,
        start: usize,
        hold_len: usize,
    };

    pub fn init(alloc: std.mem.Allocator) Animation {
        return .{ .alloc = alloc };
    }

    pub fn deinit(self: Animation) void {
        self.frames.deinit(self.alloc);
    }

    pub fn tick(self: *Animation, time: ztg.base.Time) void {
        self.frame_time += if (self.use_realtime) time.real_dt else time.dt;

        if (self.frame_time >= 1 / self.frames_per_sec) {
            self.frames_elapsed += 1;
            self.frame_time = 0;

            if (self.frames_elapsed >= self.frame_start + self.frames.items(.hold_len)[self.cur_frame]) {
                self.cur_frame += 1;
            }
        }
    }

    pub fn getFrame(self: Animation) Frame {
        return self.frames.get(self.cur_frame);
    }

    pub fn reset(self: *Animation) void {
        self.frame_time = 0;
        self.current = 0;
    }
};

pub const Frame = struct {
    tex: rl.Texture,
    source: rl.Rectangle,
    color: rl.Color,
};

pub fn init(alloc: std.mem.Allocator, comptime Animations: type, comptime Events: type, default_anim: Animations) Self {
    return .{
        .state = ztg.StateMachine.init(alloc, Animations, Events, default_anim, onTransition),
        .anims = alloc.alloc(Animation, std.meta.fields(Animations).len),
    };
}

pub fn deinit(self: Self) void {
    self.state.alloc.free(self.anims);
    self.state.deinit();
}

pub fn defineAnim(self: *Self, anim_tag: anytype, anim_def: Animation) !void {
    self.anims[try self.state.convertTo(.state, anim_tag)] = anim_def;
}

pub fn invoke(self: *Self, ctx: ?*anyopaque, event: anytype) !void {
    try self.state.invoke(ctx, event);
}

fn onTransition(ctx: ?*anyopaque, _: ?usize, from: usize, to: usize) !void {
    var self: Self = @ptrCast(@alignCast(ctx));

    self.anims[from].reset();
    self.cur_anim = to;
}
