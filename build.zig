const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const api_path = "./src/api";
    const dump_cmd = b.addSystemCommand(&.{
        "godot", "--dump-extension-api", "--dump-gdextension-interface",
    });
    dump_cmd.setCwd(.{ .cwd_relative = api_path });

    const binding_generator = b.addExecutable(.{ .name = "binding_generator", .target = target, .root_source_file = .{ .path = "binding_generator/main.zig" } });
    binding_generator.addIncludePath(.{ .path = api_path });
    binding_generator.step.dependOn(&dump_cmd.step);

    const generate_binding = std.Build.Step.Run.create(b, "bind_godot");
    generate_binding.addArtifactArg(binding_generator);
    const bind_step = b.step("bind", "generate godot bindings");
    bind_step.dependOn(&generate_binding.step);

    const lib = b.addSharedLibrary(.{
        .name = "example",
        .root_source_file = .{ .path = "src/ExamplePlugin.zig" },
        .target = target,
        .optimize = optimize,
    });

    lib.addIncludePath(.{ .path = api_path });
    lib.linkLibC();
    b.lib_dir = "./project/lib";
    b.installArtifact(lib);
}
