const std = @import("std");
const Godot = @import("godot");
const Vec2 = Godot.Vector2;
const Self = @This();

pub usingnamespace Godot.Control;
base: Godot.Control,

sprite: Godot.Sprite2D,

pub fn _enter_tree(self: *Self) void {
    if (Godot.Engine.getSingleton().isEditorHint()) return;

    var normal_btn = Godot.initButton();
    self.addChild(normal_btn, false, Godot.Node.INTERNAL_MODE_DISABLED);
    normal_btn.setPosition(Vec2.new(100, 20), false);
    normal_btn.setSize(Vec2.new(100, 50), false);
    normal_btn.setText("Press Me");

    var toggle_btn = Godot.initCheckBox();
    self.addChild(toggle_btn, false, Godot.Node.INTERNAL_MODE_DISABLED);
    toggle_btn.setPosition(Vec2.new(320, 20), false);
    toggle_btn.setSize(Vec2.new(100, 50), false);
    toggle_btn.setText("Toggle Me");

    Godot.connect(toggle_btn, "toggled", self, "on_toggled");
    Godot.connect(normal_btn, "pressed", self, "on_pressed");

    const resource_loader = Godot.ResourceLoader.getSingleton();
    const res_name = Godot.String.initFromLatin1Chars("res://textures/logo.png");
    const texture = resource_loader.load(res_name, "", Godot.ResourceLoader.CACHE_MODE_REUSE);
    if (texture) |tex| {
        defer _ = Godot.unreference(tex);
        self.sprite = Godot.initSprite2D();
        self.sprite.setTexture(tex);
        self.sprite.setPosition(Vec2.new(400, 300));
        self.sprite.setScale(Vec2.new(0.6, 0.6));
        self.addChild(self.sprite, false, Godot.Node.INTERNAL_MODE_DISABLED);
    }
}

pub fn _exit_tree(self: *Self) void {
    _ = self;
}

pub fn on_pressed(self: *Self) void {
    _ = self;
    std.debug.print("on_pressed \n", .{});
}

pub fn on_toggled(self: *Self, toggled_on: bool) void {
    _ = self;
    std.debug.print("on_toggled {any}\n", .{toggled_on});
}
