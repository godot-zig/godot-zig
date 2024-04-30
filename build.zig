const std = @import("std");

const api_path = "src/api";

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const precision = b.option([]const u8, "precision", "Floating point precision, either `float` or `double` [default: `float`]") orelse "float";
    const godot_path = b.option([]const u8, "godot", "Path to Godot engine binary [default: `godot`]") orelse "godot";

    const module = b.addModule("godot", .{
        .root_source_file = .{ .path = "src/api/Godot.zig" },
        .target = target,
        .optimize = optimize,
    });

    const build_options = b.addOptions();
    build_options.addOption([]const u8, "precision", precision);
    module.addOptions("build_options", build_options);

    const generated = generateBindings(b, target, precision, godot_path);
    generated.addImport("godot", module);
    module.addImport("gen", generated);

    module.link_libc = true;
    module.addIncludePath(b.path(api_path));

    // Example project
    const lib = b.addSharedLibrary(.{
        .name = "example",
        .root_source_file = .{ .path = "src/ExamplePlugin.zig" },
        .target = target,
        .optimize = optimize,
    });
    lib.root_module.addImport("godot", module);

    b.lib_dir = "./project/lib";
    b.installArtifact(lib);

    const run_cmd = b.addSystemCommand(&.{
        godot_path, "--path", "./project",
    });
    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run with Godot");
    run_step.dependOn(&run_cmd.step);
}

pub fn generateBindings(b: *std.Build, target: std.Build.ResolvedTarget, precision: []const u8, godot_path: []const u8) *std.Build.Module {
    // Run godot to dump the API info
    // This runner script is required for caching because Godot outputs to CWD
    const godot_runner = b.addExecutable(.{
        .name = "run_godot_dump",
        .root_source_file = .{ .path = "binding_generator/run_godot_dump.zig" },
        .target = b.host,
    });
    const dump_cmd = b.addRunArtifact(godot_runner);
    const dump_path = dump_cmd.addOutputFileArg("extension_api.json");
    dump_cmd.addArgs(&.{
        godot_path, "--dump-extension-api", "--dump-gdextension-interface", "--headless",
    });

    // Run the binding generator
    const binding_generator = b.addExecutable(.{
        .name = "binding_generator",
        .root_source_file = .{ .path = "binding_generator/main.zig" },
        .target = b.host,
    });
    binding_generator.addIncludePath(dump_path.dirname());

    const generate_binding = b.addRunArtifact(binding_generator);
    generate_binding.addDirectoryArg(dump_path);
    generate_binding.addArg(b.fmt("{s}_{}", .{ precision, target.result.ptrBitWidth() }));
    const gen_path = generate_binding.addOutputFileArg("entrypoint.zig");

    const mod = b.createModule(.{
        .root_source_file = gen_path,
    });
    mod.addIncludePath(dump_path.dirname());

    return mod;
}
