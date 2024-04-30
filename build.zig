const std = @import("std");

const api_path = "src/api";

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const precision = b.option([]const u8, "precision", "Floating point precision, either `float` or `double` [default: `float`]") orelse "float";
    const godot_path = b.option([]const u8, "godot", "Path to Godot engine binary [default: `godot`]") orelse "godot";

    const bind_step = createBindStep(b, target, precision, godot_path);

    // Example project
    const lib = b.addSharedLibrary(.{
        .name = "example",
        .root_source_file = .{ .path = "src/ExamplePlugin.zig" },
        .target = target,
        .optimize = optimize,
    });

    const build_options = b.addOptions();
    build_options.addOption([]const u8, "precision", precision);
    lib.root_module.addOptions("build_options", build_options);

    lib.addIncludePath(b.path(api_path));
    lib.linkLibC();
    lib.step.dependOn(bind_step);

    b.lib_dir = "./project/lib";
    b.installArtifact(lib);

    const run_cmd = b.addSystemCommand(&.{
        godot_path, "--path", "./project",
    });
    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run with Godot");
    run_step.dependOn(&run_cmd.step);
}

pub fn createBindStep(b: *std.Build, target: std.Build.ResolvedTarget, precision: []const u8, godot_path: []const u8) *std.Build.Step {
    const dump_cmd = b.addSystemCommand(&.{
        godot_path, "--dump-extension-api", "--dump-gdextension-interface", "--headless",
    });
    const out_path = b.pathJoin(&.{ thisDir(), api_path });
    dump_cmd.setCwd(.{ .cwd_relative = out_path });
    const dump_step = b.step("dump", "dump api");
    dump_step.dependOn(&dump_cmd.step);

    const binding_generator = b.addExecutable(.{ .name = "binding_generator", .target = target, .root_source_file = .{ .path = b.pathJoin(&.{ thisDir(), "binding_generator/main.zig" }) } });
    binding_generator.addIncludePath(.{ .path = out_path });
    binding_generator.step.dependOn(dump_step);

    const generate_binding = std.Build.Step.Run.create(b, "bind_godot");
    generate_binding.addArtifactArg(binding_generator);
    generate_binding.addArgs(&.{
        out_path,
        precision,
        b.fmt("{}", .{target.result.ptrBitWidth()}),
    });

    const bind_step = b.step("bind", "generate godot bindings");
    bind_step.dependOn(&generate_binding.step);
    return bind_step;
}

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
