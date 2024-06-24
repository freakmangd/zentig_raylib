const std = @import("std");
const Build = std.Build;

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const raylib_dep_ptr = b.option(usize, "raylib_dep_ptr", "override raylib dependency ptr");

    const raylib_dep: *Build.Dependency = if (raylib_dep_ptr) |ptr| blk: {
        break :blk @ptrFromInt(ptr);
    } else blk: {
        break :blk b.dependency("raylib", .{
            .target = target,
            .optimize = optimize,
        });
    };
    const raylib = raylib_dep.artifact("raylib");
    b.installArtifact(raylib);

    const zentig_path_ptr = b.option(usize, "zentig_module_ptr", "override zentig module ptr");

    const zentig_mod: *Build.Module = if (zentig_path_ptr) |ptr| blk: {
        break :blk @ptrFromInt(ptr);
    } else blk: {
        const zentig_dep = b.dependency("zentig", .{
            .target = target,
            .optimize = optimize,
        });
        break :blk zentig_dep.module("zentig");
    };

    b.modules.put("zentig", zentig_mod) catch @panic("OOM");

    const zentig_raylib = b.addModule("zentig-raylib", .{
        .root_source_file = b.path("src/init.zig"),
        .imports = &.{
            .{ .name = "zentig", .module = zentig_mod },
        },
    });
    zentig_raylib.addIncludePath(raylib_dep.path("src"));

    // Local testing

    const all_tests = b.addTest(.{
        .root_source_file = b.path("src/init.zig"),
        .target = target,
        .optimize = optimize,
    });
    all_tests.root_module.addImport("zentig", zentig_mod);
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
            .root_source_file = b.path(ex_info[1]),
            .target = target,
            .optimize = optimize,
        });

        example.root_module.addImport("zentig", zentig_mod);
        example.root_module.addImport("zrl", zentig_raylib);
        example.linkLibrary(raylib);
        example.linkLibC();

        const run_example_cmd = b.addRunArtifact(example);

        const run_example_step = b.step(ex_info[0], ex_info[2]);
        run_example_step.dependOn(&run_example_cmd.step);

        all_tests_step.dependOn(&example.step);
    }
}
