const std = @import("std");

pub fn StreamBuilder(comptime T: type, comptime size: u32) type {
    return struct {
        pub const BufferType = [size]T;
        pub const FBSType = std.io.FixedBufferStream([]T);
        buf: BufferType = undefined,
        fbs: FBSType = undefined,
        allocator: std.mem.Allocator,
        writer: FBSType.Writer,
        last_write_pos: usize,
        const Self = @This();
        pub const IdentWidth = 4;
        pub fn init(allocator: std.mem.Allocator) !*Self {
            var self = try allocator.create(Self);
            self.fbs = std.io.fixedBufferStream(&self.buf);
            self.writer = self.fbs.writer();
            self.allocator = allocator;
            self.last_write_pos = self.fbs.pos;
            return self;
        }

        pub fn deinit(self: *Self) void {
            self.allocator.destroy(self);
        }

        pub fn reset(self: *Self) void {
            self.fbs.pos = 0;
        }

        pub fn getWritten(self: *Self) []T {
            return self.fbs.getWritten();
        }

        pub fn getLastWritten(self: *Self) []T {
            return self.buf[self.last_write_pos..self.fbs.pos];
        }

        pub fn bufPrint(self: *Self, comptime format: []const u8, args: anytype) ![]T {
            self.last_write_pos = self.fbs.pos;
            try self.writer.print(format, args);
            return self.getLastWritten();
        }

        pub fn print(self: *Self, indent_level: u8, comptime line: []const u8, args: anytype) !void {
            self.last_write_pos = self.fbs.pos;
            for (0..indent_level * IdentWidth) |_| {
                _ = try self.writer.write(" ");
            }
            try self.writer.print(line, args);
        }

        pub fn printLine(self: *Self, indent_level: u8, comptime line: []const u8, args: anytype) !void {
            self.last_write_pos = self.fbs.pos;
            for (0..indent_level * IdentWidth) |_| {
                _ = try self.writer.write(" ");
            }
            try self.writer.print(line, args);
            _ = try self.writer.writeAll("\n");
        }

        pub fn writeLine(self: *Self, indent_level: u8, line: []const u8) !void {
            self.last_write_pos = self.fbs.pos;
            for (0..indent_level * IdentWidth) |_| {
                _ = try self.writer.write(" ");
            }
            _ = try self.writer.writeAll(line);
            _ = try self.writer.writeAll("\n");
        }
    };
}
