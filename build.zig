const std = @import("std");

const api_path = "src/api";

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
    const precision = b.option([]const u8, "precision", "double") orelse "float";
    const arch = b.option([]const u8, "arch", "32") orelse "64";

    const bind_step = createBindStep(b, target, precision, arch);

    const lib = b.addSharedLibrary(.{
        .name = "example",
        .root_source_file = .{ .path = "src/ExamplePlugin.zig" },
        .target = target,
        .optimize = optimize,
    });

    const build_options = b.addOptions();
    build_options.addOption([]const u8, "precision", precision);
    build_options.addOption([]const u8, "arch", arch);
    lib.root_module.addOptions("build_options", build_options);

    lib.addIncludePath(.{ .path = b.pathJoin(&.{ thisDir(), api_path }) });
    lib.linkLibC();
    lib.step.dependOn(bind_step);

    b.lib_dir = "./project/lib";
    b.installArtifact(lib);

    const run_cmd = b.addSystemCommand(&.{
        "godot", "--path", "./project",
    });
    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "run with Godot");
    run_step.dependOn(&run_cmd.step);
}

pub fn createBindStep(b: *std.Build, target: std.Build.ResolvedTarget, precision:[]const u8, arch:[]const u8) *std.Build.Step {


    const dump_cmd = b.addSystemCommand(&.{
        "godot", "--dump-extension-api", "--dump-gdextension-interface",
    });
    const out_path = b.pathJoin(&.{ thisDir(), api_path });
    dump_cmd.setCwd(.{ .cwd_relative = out_path });
    const dump_step = b.step("dump", "dump api");
    dump_step.dependOn(&dump_cmd.step);

    const binding_generator = b.addExecutable(.{ .name = "binding_generator", .target = target, .root_source_file = .{ .path = b.pathJoin(&.{ thisDir(), "binding_generator/main.zig" }) } });
    binding_generator.addIncludePath(.{ .path = out_path });
    //binding_generator.step.dependOn(dump_step);

    const generate_binding = std.Build.Step.Run.create(b, "bind_godot");
    generate_binding.addArtifactArg(binding_generator);
    generate_binding.addArgs(&.{out_path, precision, arch});

    const bind_step = b.step("bind", "generate godot bindings");
    bind_step.dependOn(&generate_binding.step);
    return bind_step;
}

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
