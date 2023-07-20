const std = @import("std");
const Build = std.Build;

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const raylib_dep = b.dependency("raylib", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib = raylib_dep.artifact("raylib");
    b.installArtifact(raylib);

    const raylib_mod = b.addModule("raylib", .{
        .source_file = .{ .path = Build.FileSource.relative("src/init_raylib.zig") },
    });

    const zentig_dep = b.dependency("zentig", .{});

    const zentig_raylib = b.addModule("zentig-raylib", .{
        .source_file = Build.FileSource.relative("src/init.zig"),
        .dependencies = &.{
            .{ .name = "zentig", .module = zentig_dep.module("zentig") },
            .{ .name = "raylib", .module = raylib_mod },
        },
    });

    // Examples
    const example = b.addExecutable(.{
        .name = "zentig-raylib-example",
        .root_source_file = Build.FileSource.relative("examples/2d_sprite_example.zig"),
        .target = target,
        .optimize = optimize,
    });
    example.addModule("raylib", raylib_mod);
    example.addModule("zentig", zentig_dep.module("zentig"));
    example.addModule("zrl", zentig_raylib);
    example.linkLibrary(raylib);

    const run_example = b.addRunArtifact(example);
    const example_step = b.step("2d_sprite", "Run 2d sprite example");

    example_step.dependOn(&run_example.step);
}

pub fn addAsModule(
    mod_name: []const u8,
    zentig_mod: anytype,
    rl_build: anytype,
    rl_include_path: []const u8,
    options: struct {
        import_raylib_as: ?[]const u8 = null,
        override_target: ?std.zig.CrossTarget = null,
        override_optimize: ?std.builtin.OptimizeMode = null,
        override_build: ?*std.Build = null,
        override_exe: ?*std.build.Step.Compile = null,
    },
) struct { raylib: *Build.Module, zrl: *Build.Module } {
    const b = options.override_build orelse zentig_mod.b;
    const exe: *std.build.Step.Compile = options.override_exe orelse zentig_mod.exe;

    const raylib = rl_build.addRaylib(b, options.override_target orelse zentig_mod.target, options.override_optimize orelse zentig_mod.optimize, .{});

    const raylib_mod = b.createModule(.{
        .source_file = .{ .path = srcdir ++ "/src/init_raylib.zig" },
    });

    if (options.import_raylib_as) |impas| exe.addModule(impas, raylib_mod);
    exe.addIncludePath(rl_include_path);
    exe.linkLibrary(raylib);

    const zentig_rl = b.createModule(.{
        .source_file = .{ .path = srcdir ++ "/src/init.zig" },
        .dependencies = &.{
            .{ .name = "zentig", .module = zentig_mod.zentig_mod },
            .{ .name = "zmath", .module = zentig_mod.zmath_mod },
            .{ .name = "raylib", .module = raylib_mod },
        },
    });
    exe.addModule(mod_name, zentig_rl);

    return .{ .raylib = raylib_mod, .zrl = zentig_rl };
}

const srcdir = struct {
    fn getSrcDir() []const u8 {
        return std.fs.path.dirname(@src().file).?;
    }
}.getSrcDir();
