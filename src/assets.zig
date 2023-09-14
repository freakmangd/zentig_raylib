const std = @import("std");
const ztg = @import("zentig");
const zrl = @import("init.zig");
const rl = @import("raylib");

const Self = @This();

alloc: std.mem.Allocator,
tex_map: std.StringHashMapUnmanaged(rl.Texture) = .{},
sound_map: std.StringHashMapUnmanaged(rl.Sound) = .{},

pub const AssetError = error{FileNotFound} || std.mem.Allocator.Error;

pub fn texture(self: *Self, filename: [:0]const u8) AssetError!rl.Texture {
    return self.textureOrNull(filename) orelse blk: {
        const tex = rl.LoadTexture(filename.ptr);
        if (tex.id == 0) {
            zrl.log.err("Assets: Could not found the texture file {s}", .{filename});
            return error.FileNotFound;
        }

        try self.tex_map.put(self.alloc, filename, tex);
        break :blk tex;
    };
}

pub inline fn textureOrNull(self: Self, filename: [:0]const u8) ?rl.Texture {
    return self.tex_map.get(filename);
}

pub fn sound(self: *Self, filename: [:0]const u8) AssetError!rl.Sound {
    return self.soundOrNull(filename) orelse blk: {
        const snd = rl.LoadSound(filename);
        if (snd.stream.buffer == null) {
            zrl.log.err("Assets: Could not found the sound file {s}", .{filename});
            return error.FileNotFound;
        }

        try self.sound_map.put(self.alloc, filename, snd);
        break :blk snd;
    };
}

pub inline fn soundOrNull(self: Self, filename: [:0]const u8) ?rl.Sound {
    return self.sound_map.get(filename);
}

pub fn include(comptime wb: *ztg.WorldBuilder) void {
    wb.addResource(Self, .{ .alloc = undefined });
    wb.addSystems(.{
        .init = ini_TexIndex,
        .deinit = dei_TexIndex,
    });
}

fn ini_TexIndex(alloc: std.mem.Allocator, self: *Self) void {
    self.alloc = alloc;
}

fn dei_TexIndex(self: *Self) void {
    var tex_iter = self.tex_map.valueIterator();
    while (tex_iter.next()) |tex| {
        rl.UnloadTexture(tex.*);
    }
    self.tex_map.deinit(self.alloc);

    var sound_iter = self.sound_map.valueIterator();
    while (sound_iter.next()) |snd| {
        rl.UnloadSound(snd.*);
    }
    self.sound_map.deinit(self.alloc);
}
