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
        .source_file = Build.LazyPath.relative("src/init_raylib.zig"),
    });

    const zentig_dep = b.dependency("zentig", .{
        .target = target,
        .optimize = optimize,
    });
    const zentig_mod = zentig_dep.module("zentig");

    b.modules.put("zentig", zentig_mod) catch @panic("OOM");

    const zentig_raylib = b.addModule("zentig-raylib", .{
        .source_file = Build.LazyPath.relative("src/init.zig"),
        .dependencies = &.{
            .{ .name = "zentig", .module = zentig_mod },
            .{ .name = "raylib", .module = raylib_mod },
        },
    });

    // Local testing

    const all_tests = b.addTest(.{
        .root_source_file = Build.LazyPath.relative("src/init.zig"),
        .target = target,
        .optimize = optimize,
    });
    all_tests.addModule("zentig", zentig_mod);
    all_tests.addModule("raylib", raylib_mod);
    all_tests.linkLibrary(raylib);
    all_tests.linkLibC();

    const run_all_tests = b.addRunArtifact(all_tests);

    const all_tests_step = b.step("test", "Run all tests and try to build all examples.");
    all_tests_step.dependOn(&run_all_tests.step);

    const examples = [_]struct { []const u8, []const u8, []const u8 }{
        .{ "2d_sprite", "examples/2d_sprite_example.zig", "Run 2d sprite example" },
        .{ "topdown_movement", "examples/2d_topdown_movement.zig", "Run 2d topdown movement example" },
    };

    for (examples) |ex_info| {
        const example = b.addExecutable(.{
            .name = ex_info[0],
            .root_source_file = Build.LazyPath.relative(ex_info[1]),
            .target = target,
            .optimize = optimize,
        });

        example.addModule("zentig", zentig_mod);
        example.addModule("zrl", zentig_raylib);
        example.linkLibrary(raylib);
        example.linkLibC();

        const run_example_cmd = b.addRunArtifact(example);

        const run_example_step = b.step(ex_info[0], ex_info[2]);
        run_example_step.dependOn(&run_example_cmd.step);

        //all_tests_step.dependOn(&example.step);
    }
}

pub fn addAsLocalModule(
    zentig_mod: anytype, // only doing anytype so i dont have to figure out how to get the actual type
    comptime rl_build: type,
    options: struct {
        name: []const u8,
        rl_include_path: []const u8,
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
    exe.addIncludePath(.{ .path = options.rl_include_path });
    exe.linkLibrary(raylib);

    const zentig_rl = b.createModule(.{
        .source_file = .{ .path = srcdir ++ "/src/init.zig" },
        .dependencies = &.{
            .{ .name = "zentig", .module = zentig_mod.zentig_mod },
            .{ .name = "zmath", .module = zentig_mod.zmath_mod },
            .{ .name = "raylib", .module = raylib_mod },
        },
    });
    exe.addModule(options.name, zentig_rl);

    return .{ .raylib = raylib_mod, .zrl = zentig_rl };
}

const srcdir = struct {
    fn getSrcDir() []const u8 {
        return std.fs.path.dirname(@src().file).?;
    }
}.getSrcDir();
