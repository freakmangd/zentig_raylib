# zentig_raylib
Raylib bindings and ecs wrappers for zentig

## Usage

Mods available for the `WorldBuilder` are:

(assuming `zrl == @import("zentig-raylib");`)
+ `zrl` contains: `Sprite`, `Camera2d`
+ `zrl.physics` - contains: `ColBox`

## Installation

### Locally

Clone this and raylib into a folder in your project root (ex: `lib`) and add these lines to your `build.zig`
```zig
// ztg comes from zentig.addAsLocalModule
_ = zrl.addAsLocalModule(ztg, @import("lib/raylib/src/build.zig"), .{
    .name = "zrl",
    .rl_include_path = "lib/raylib/src/",
});
```

You can also choose to import raylib as its own module into your project:
```zig
_ = zrl.addAsLocalModule(ztg, @import("lib/raylib/src/build.zig"), .{
    .name = "zrl",
    .rl_include_path = "lib/raylib/src/",

    .import_raylib_as = "raylib", // add this line
});
```

### Package Manager

After adding your dependency to `build.zig.zon` do this in your `build.zig`:
```zig
const zrl_dep = b.dependency("zentig_raylib", .{
    .target = target,
    .optimize = optimize,
});
exe.addModule("zentig", zrl_dep.module("zentig")); // Zentig raylib exposes zentig so you only need one dependency
exe.addModule("zrl", zrl_dep.module("zentig-raylib"));
exe.linkLibrary(zrl_dep.artifact("raylib"));
```
