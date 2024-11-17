const std = @import("std");

pub fn build(b: *std.Build) !void {
    //var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    //defer _ = gpa.deinit();
    //const alloc = gpa.allocator();

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const godot_path = b.option([]const u8, "godot", "Path to Godot engine binary [default: `godot`]") orelse "godot";
    const precision = b.option([]const u8, "precision", "Floating point precision, either `float` or `double` [default: `float`]") orelse "float";
    const arch = b.option([]const u8, "arch", "32") orelse "64";
    const headers = b.option(
        []const u8,
        "headers",
        "Where to source Godot header files. [options: GENERATED, VENDORED, <dir_path>] [default: GENERATED]",
    ) orelse "GENERATED";

    const bindgen_path = b.makeTempPath();
    const dump_step = try build_dump_step(b, godot_path, headers, bindgen_path);
    const binding_generator_step = b.step("binding_generator", "Build the binding_generator program");
    const binding_generator = b.addExecutable(.{
        .name = "binding_generator",
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path(b.pathJoin(&.{ "binding_generator", "main.zig" })),
        .link_libc = true,
    });
    binding_generator.step.dependOn(dump_step);
    binding_generator.addIncludePath(.{ .cwd_relative = bindgen_path });
    binding_generator_step.dependOn(&binding_generator.step);
    b.installArtifact(binding_generator);

    const bindgen_step = build_bindgen_step(b, binding_generator, bindgen_path, precision, arch);
    bindgen_step.dependOn(binding_generator_step);

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
        .root_source_file = .{ .cwd_relative = b.pathJoin(&.{ bindgen_path, "GodotCore.zig" }) },
        .target = target,
        .optimize = optimize,
    });
    core_module.addIncludePath(.{ .cwd_relative = bindgen_path });
    core_module.addImport("godot", &lib.root_module);
    lib.root_module.addImport("GodotCore", core_module);

    const build_options = b.addOptions();
    build_options.addOption([]const u8, "precision", precision);
    build_options.addOption([]const u8, "headers", headers);
    lib.root_module.addOptions("build_options", build_options);
    lib.addIncludePath(.{ .cwd_relative = bindgen_path });
    lib.step.dependOn(bindgen_step);
    b.installArtifact(lib);
}

fn build_bindgen_step(
    b: *std.Build,
    binding_generator: *std.Build.Step.Compile,
    bindgen_path: []const u8,
    precision: []const u8,
    arch: []const u8,
) *std.Build.Step {
    const bind_step = b.step("bindgen", "Generate godot bindings");
    const generate_binding = std.Build.Step.Run.create(b, "bind_godot");
    const output_path = b.makeTempPath();
    //const export_path = b.makeTempPath();
    generate_binding.addArtifactArg(binding_generator);
    //const exe = b.getInstallPath(.bin, "binding_generator");
    generate_binding.addArgs(&.{ bindgen_path, output_path, precision, arch });
    //const install_binding = b.addInstallDirectory(.{ .source_dir = .{ .cwd_relative = export_path }, .install_dir = .prefix, .install_subdir = "api" });
    //install_binding.step.dependOn(&generate_binding.step);
    //bind_step.dependOn(&install_binding.step);
    const mv_cmd = b.addSystemCommand(&.{
        //"mv", b.pathJoin(&.{ output_path, "*.zig" }), bindgen_path,
        "bash", "-c", b.fmt("mv {s}/*.zig {s}", .{ output_path, bindgen_path }),
    });
    mv_cmd.step.dependOn(&generate_binding.step);
    bind_step.dependOn(&mv_cmd.step);
    return bind_step;
}

fn build_dump_step(
    b: *std.Build,
    godot_path: []const u8,
    headers_option: []const u8,
    bindgen_path: []const u8,
) !*std.Build.Step {
    const dump_step = b.step("dump", "dump godot headers");
    //const tmpdir = b.makeTempPath();
    if (std.mem.eql(u8, headers_option, "VENDORED")) {
        const vendor_json = std.Build.LazyPath{ .src_path = .{ .owner = b, .sub_path = b.pathJoin(&.{ "vendor", "extension_api.json" }) } };
        const vendor_h = std.Build.LazyPath{ .src_path = .{ .owner = b, .sub_path = b.pathJoin(&.{ "vendor", "gdextension_interface.h" }) } };
        const copy_to_bindgen = b.addSystemCommand(&.{
            "cp", vendor_json.getPath2(b, dump_step), vendor_h.getPath2(b, dump_step), bindgen_path,
        });
        dump_step.dependOn(&copy_to_bindgen.step);
        const api_json = b.addInstallFile(vendor_json, b.pathJoin(&.{ "api", "extension_api.json" }));
        dump_step.dependOn(&api_json.step);
        const iface_headers = b.addInstallFile(vendor_h, b.pathJoin(&.{ "api", "gdextension_interface.h" }));
        dump_step.dependOn(&iface_headers.step);
    } else if (std.mem.eql(u8, headers_option, "GENERATED")) {
        const output_dir = b.addInstallDirectory(.{
            .source_dir = .{ .cwd_relative = bindgen_path },
            .install_dir = .prefix,
            .install_subdir = "api",
        });
        const dump_cmd = b.addSystemCommand(&.{
            godot_path, "--dump-extension-api", "--dump-gdextension-interface", "--headless",
        });
        dump_cmd.setCwd(.{ .cwd_relative = bindgen_path });
        output_dir.step.dependOn(&dump_cmd.step);
        dump_step.dependOn(&output_dir.step);
    } else {
        const custom_json = b.pathJoin(&.{ headers_option, "extension_api.json" });
        const custom_h = b.pathJoin(&.{ headers_option, "gdextension_interface.h" });
        const copy_to_bindgen = b.addSystemCommand(&.{
            "cp", custom_json, custom_h, bindgen_path,
        });
        dump_step.dependOn(&copy_to_bindgen.step);
        const iface_headers = b.addInstallFile(
            .{ .cwd_relative = custom_json },
            b.pathJoin(&.{ "api", "extension_api.json" }),
        );
        dump_step.dependOn(&iface_headers.step);
        const api_json = b.addInstallFile(
            .{ .cwd_relative = custom_h },
            b.pathJoin(&.{ "api", "gdextension_interface.h" }),
        );
        dump_step.dependOn(&api_json.step);
    }
    return dump_step;
}
