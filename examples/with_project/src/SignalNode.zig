const std = @import("std");
const Godot = @import("godot");
const Vec2 = Godot.Vector2;
const Vec3 = Godot.Vector3;
const Self = @This();

pub usingnamespace Godot.Control;
base: Godot.Control, //this makes @Self a valid gdextension class
color_rect: Godot.ColorRect = undefined,

pub fn _bind_methods() void {
    Godot.registerSignal(Self, "signal1", &[_]Godot.PropertyInfo{
        Godot.PropertyInfo.init(Godot.GDEXTENSION_VARIANT_TYPE_STRING, Godot.StringName.initFromLatin1Chars("name")),
        Godot.PropertyInfo.init(Godot.GDEXTENSION_VARIANT_TYPE_VECTOR3, Godot.StringName.initFromLatin1Chars("position")),
    });

    Godot.registerSignal(Self, "signal2", &.{});
    Godot.registerSignal(Self, "signal3", &.{});
}

pub fn _enter_tree(self: *Self) void {
    if (Godot.Engine.getSingleton().isEditorHint()) return;

    var signal1_btn = Godot.initButton();
    self.addChild(signal1_btn, false, Godot.Node.INTERNAL_MODE_DISABLED);
    signal1_btn.setPosition(Vec2.new(100, 20), false);
    signal1_btn.setSize(Vec2.new(100, 50), false);
    signal1_btn.setText("Signal1");

    var signal2_btn = Godot.initButton();
    self.addChild(signal2_btn, false, Godot.Node.INTERNAL_MODE_DISABLED);
    signal2_btn.setPosition(Vec2.new(250, 20), false);
    signal2_btn.setSize(Vec2.new(100, 50), false);
    signal2_btn.setText("Signal2");

    var signal3_btn = Godot.initButton();
    self.addChild(signal3_btn, false, Godot.Node.INTERNAL_MODE_DISABLED);
    signal3_btn.setPosition(Vec2.new(400, 20), false);
    signal3_btn.setSize(Vec2.new(100, 50), false);
    signal3_btn.setText("Signal3");

    self.color_rect = Godot.initColorRect();
    self.addChild(self.color_rect, false, Godot.Node.INTERNAL_MODE_DISABLED);
    self.color_rect.setPosition(Vec2.new(400, 400), false);
    self.color_rect.setSize(Vec2.new(100, 100), false);
    self.color_rect.setColor(Godot.Color.initFromF64F64F64F64(1, 0, 0, 1));

    Godot.connect(signal1_btn, "pressed", self, "emitSignal1");
    Godot.connect(signal2_btn, "pressed", self, "emitSignal2");
    Godot.connect(signal3_btn, "pressed", self, "emitSignal3");
    Godot.connect(self, "signal1", self, "onSignal1");
    Godot.connect(self, "signal2", self, "onSignal2");
    Godot.connect(self, "signal3", self, "onSignal3");
}

pub fn _exit_tree(self: *Self) void {
    _ = self;
}

pub fn onSignal1(_: *Self, name: Godot.StringName, position: Godot.Vector3) void {
    var buf: [256]u8 = undefined;
    const n = Godot.stringNameToAscii(name, &buf);
    std.debug.print("sianal1 received : name = {s} position={any}\n", .{ n, position });
}

pub fn onSignal2(self: *Self) void {
    self.color_rect.setColor(Godot.Color.initFromF64F64F64F64(0, 1, 0, 1));
}

pub fn onSignal3(self: *Self) void {
    self.color_rect.setColor(Godot.Color.initFromF64F64F64F64(1, 0, 0, 1));
}

pub fn emitSignal1(self: *Self) void {
    _ = self.emitSignal("signal1", .{ Godot.String.initFromLatin1Chars("test_signal_name"), Vec3.new(123, 321, 333) });
}
pub fn emitSignal2(self: *Self) void {
    _ = self.emitSignal("signal2", .{});
}
pub fn emitSignal3(self: *Self) void {
    _ = self.emitSignal("signal3", .{});
}
