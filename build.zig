const std = @import("std");

pub fn build(b: *std.Build) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const godot_path = b.option([]const u8, "godot", "Path to Godot engine binary [default: `godot`]") orelse "godot";

    const precision = b.option([]const u8, "precision", "Floating point precision, either `float` or `double` [default: `float`]") orelse "float";
    const arch = b.option([]const u8, "arch", "32") orelse "64";
    const export_path = b.option([]const u8, "output", "Path to save auto-generated files [default: `./gen`]") orelse "./gen";
    const headers = b.option(
        []const u8,
        "headers",
        "Where to source Godot header files. [options: GENERATED, VENDORED, <dir_path>] [default: GENERATED]",
    ) orelse "GENERATED";
    const api_path = b.pathJoin(&.{ export_path, "api" });

    std.fs.cwd().makePath(export_path) catch unreachable;

    const dump_step = try build_dump_step(alloc, b, export_path, godot_path, headers);

    const binding_generator_step = b.step("binding_generator", "Build the binding_generator program");
    const binding_generator = b.addExecutable(.{
        .name = "binding_generator",
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path(b.pathJoin(&.{ "binding_generator", "main.zig" })),
        .link_libc = true,
    });
    binding_generator.step.dependOn(dump_step);
    binding_generator.addIncludePath(b.path(export_path));
    binding_generator.addIncludePath(b.path(api_path));
    binding_generator_step.dependOn(&binding_generator.step);
    _ = b.installArtifact(binding_generator);

    const generate_binding = std.Build.Step.Run.create(b, "bind_godot");
    generate_binding.addArtifactArg(binding_generator);
    generate_binding.addArgs(&.{ export_path, api_path, precision, arch });

    const bind_step = b.step("bind", "Generate godot bindings");
    bind_step.dependOn(&generate_binding.step);

    const lib = b.addSharedLibrary(.{
        .name = "godot",
        .root_source_file = b.path(b.pathJoin(&.{ "src", "api", "Godot.zig" })),
        .target = target,
        .optimize = optimize,
    });
    _ = b.addModule("godot", .{
        .root_source_file = b.path(b.pathJoin(&.{ "src", "api", "Godot.zig" })),
        .target = target,
        .optimize = optimize,
    });
    const core_module = b.addModule("GodotCore", .{
        .root_source_file = b.path(b.pathJoin(&.{ api_path, "GodotCore.zig" })),
        .target = target,
        .optimize = optimize,
    });
    core_module.addIncludePath(b.path(export_path));
    core_module.addImport("godot", &lib.root_module);
    lib.root_module.addImport("GodotCore", core_module);

    const build_options = b.addOptions();
    build_options.addOption([]const u8, "precision", precision);
    build_options.addOption([]const u8, "export_path", export_path);
    build_options.addOption([]const u8, "headers", headers);
    lib.root_module.addOptions("build_options", build_options);
    lib.addIncludePath(b.path(export_path));
    lib.step.dependOn(&generate_binding.step);
    b.installArtifact(lib);
}

fn build_dump_step(
    alloc: std.mem.Allocator,
    b: *std.Build,
    export_path: []const u8,
    godot_path: []const u8,
    headers: []const u8,
) !*std.Build.Step {
    const dump_step = b.step("dump", "dump godot headers");
    var dump_cmd: *std.Build.Step.Run = undefined;
    if (std.mem.eql(u8, headers, "VENDORED")) {
        dump_cmd = b.addSystemCommand(&.{
            "cp", "vendor/extension_api.json", "vendor/gdextension_interface.h", export_path,
        });
    } else if (std.mem.eql(u8, headers, "GENERATED")) {
        dump_cmd = b.addSystemCommand(&.{
            godot_path, "--dump-extension-api", "--dump-gdextension-interface", "--headless",
        });
        dump_cmd.setCwd(.{ .cwd_relative = export_path });
    } else {
        const json_path = try std.fs.path.join(alloc, &[_][]const u8{ headers, "extension_api.json" });
        const h_path = try std.fs.path.join(alloc, &[_][]const u8{ headers, "gdextension_interface.h" });
        dump_cmd = b.addSystemCommand(&.{ "cp", json_path, h_path, export_path });
    }
    dump_step.dependOn(&dump_cmd.step);
    return dump_step;
}
