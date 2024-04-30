//! Helper script to run Godot in a particular directory.
//! Required for build.zig caching integration, because Godot outputs to CWD.

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const argv = try std.process.argsAlloc(arena.allocator());
    if (argv.len < 3) {
        std.debug.print("usage: run_godot_dump EXTENSION_API_PATH GODOT_EXE ARGS...\n", .{});
        return error.NotEnoughArgs;
    }

    std.log.debug("{s}", .{argv});
    _ = try std.ChildProcess.run(.{
        .allocator = arena.allocator(),
        .argv = argv[2..],
        .cwd = std.fs.path.dirname(argv[1]).?,
    });
}

const std = @import("std");
