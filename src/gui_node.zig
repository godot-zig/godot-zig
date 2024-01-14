const std = @import("std");
const Godot = @import("api/Godot.zig");
const GDE = Godot.GDE;
const GlobalEnums = Godot.GlobalEnums;
//const Vector2 = Godot.Vector2;

godot_object: *Godot.Control,

const Self = @This();
pub usingnamespace Godot.Control;

pub fn onPressed(self: *Self) void {
    _ = self;
    std.debug.print("onPressed \n", .{});
}

pub fn onToggled(self: *Self, toggled_on: bool) void {
    _ = self;
    std.debug.print("onToggled {any}\n", .{toggled_on});
}

pub fn _enter_tree(self: *Self) void {
    if (Godot.Engine.getSingleton().is_editor_hint()) return;

    var recordBtn = Godot.Button.newButton();
    self.add_child(recordBtn, false, Godot.Node.INTERNAL_MODE_DISABLED);
    recordBtn.set_position(.{ 100, 20 }, false);
    recordBtn.set_size(.{ 100, 50 }, false);

    var playBtn = Godot.CheckBox.newCheckBox();
    self.add_child(playBtn, false, Godot.Node.INTERNAL_MODE_DISABLED);
    playBtn.set_position(.{ 220, 20 }, false);
    playBtn.set_size(.{ 100, 50 }, false);
    playBtn.set_text("Play");

    Godot.connect(playBtn, "toggled", self, "onToggled");
    Godot.connect(recordBtn, "pressed", self, "onPressed");
}

pub fn _exit_tree(self: *Self) void {
    if (Godot.Engine.getSingleton().is_editor_hint()) return;
    _ = self;
}

pub fn _physics_process(self: *Self, delta: f64) void {
    if (Godot.Engine.getSingleton().is_editor_hint()) return;
    _ = self;
    _ = delta;
}

pub fn _input(self: *Self, event: *const Godot.InputEvent) void {
    if (Godot.Engine.getSingleton().is_editor_hint()) return;
    _ = self;
    _ = event;
}
