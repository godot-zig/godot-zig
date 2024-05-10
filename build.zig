const std = @import("std");

pub fn build(_: *std.Build) void {}

pub fn createModule(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, godot_path: []const u8) *std.Build.Module {
    const precision = b.option([]const u8, "precision", "Floating point precision, either `float` or `double` [default: `float`]") orelse "float";
    const arch = b.option([]const u8, "arch", "32") orelse "64";
    const export_path = b.option([]const u8, "output", "Path to save auto-generated files [default: `./gen`]") orelse "./gen";
    const api_path = b.pathJoin(&.{ export_path, "api" });

    const dump_cmd = b.addSystemCommand(&.{
        godot_path, "--dump-extension-api", "--dump-gdextension-interface", "--headless",
    });

    std.fs.cwd().makePath(export_path) catch unreachable;

    dump_cmd.setCwd(.{ .cwd_relative = export_path });
    const dump_step = b.step("dump", "dump api");
    dump_step.dependOn(&dump_cmd.step);

    const binding_generator = b.addExecutable(.{ .name = "binding_generator", .target = target, .root_source_file = .{ .path = b.pathJoin(&.{ thisDir(), "binding_generator/main.zig" }) } });
    binding_generator.addIncludePath(.{ .path = export_path });
    binding_generator.step.dependOn(dump_step);

    const generate_binding = std.Build.Step.Run.create(b, "bind_godot");
    generate_binding.addArtifactArg(binding_generator);
    generate_binding.addArgs(&.{ export_path, api_path, precision, arch });

    const bind_step = b.step("bind", "generate godot bindings");
    bind_step.dependOn(&generate_binding.step);

    const module = b.addModule("godot", .{
        .root_source_file = .{ .path = b.pathJoin(&.{ thisDir(), "src", "api", "Godot.zig" }) },
        .target = target,
        .optimize = optimize,
    });
    const core_module = b.addModule("GodotCore", .{
        .root_source_file = .{ .path = b.pathJoin(&.{ api_path, "GodotCore.zig" }) },
        .target = target,
        .optimize = optimize,
    });
    core_module.addIncludePath(.{ .path = export_path });
    core_module.addImport("godot", module);
    module.addImport("GodotCore", core_module);

    const build_options = b.addOptions();
    build_options.addOption([]const u8, "precision", precision);
    module.addOptions("build_options", build_options);
    module.addIncludePath(.{ .path = export_path });

    return module;
}

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
