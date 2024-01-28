# godot-zig
Zig bindings for Godot 4

## Prerequisites:
1. zig master build
2. godot master build
3. making sure 'godot' command is available to generate bindings automatically.

## Building:

```
zig build bind                 # generate zig bindings for current godot version
zig build
godot -e --path ./project      # -e is only needed for the first run to get assets imported
```

## A GDExtension class example:
```
const std = @import("std");
const Godot = @import("api/Godot.zig");
const Self = @This();

pub usingnamespace Godot.Control;
godot_object: *Godot.Control, //this makes @Self a valid gdextension class

sprite: *Godot.Sprite2D = undefined,

pub fn _enter_tree(self: *Self) void {
    if (Godot.Engine.getSingleton().is_editor_hint()) return;

    var normal_btn = Godot.Button.newButton();
    self.add_child(normal_btn, false, Godot.Node.INTERNAL_MODE_DISABLED);
    normal_btn.set_position(.{ 100, 20 }, false);
    normal_btn.set_size(.{ 100, 50 }, false);
    normal_btn.set_text("Press Me");

    var toggle_btn = Godot.CheckBox.newCheckBox();
    self.add_child(toggle_btn, false, Godot.Node.INTERNAL_MODE_DISABLED);
    toggle_btn.set_position(.{ 320, 20 }, false);
    toggle_btn.set_size(.{ 100, 50 }, false);
    toggle_btn.set_text("Toggle Me");

    Godot.connect(toggle_btn, "toggled", self, "onToggled");
    Godot.connect(normal_btn, "pressed", self, "onPressed");

    const resource_loader = Godot.ResourceLoader.getSingleton();
    const tex: *Godot.Texture2D = @ptrCast(resource_loader.load("res://textures/logo.png", "", Godot.ResourceLoader.CACHE_MODE_REUSE));
    defer _ = Godot.unreference(tex);
    self.sprite = Godot.Sprite2D.newSprite2D();
    self.sprite.set_texture(tex);
    self.sprite.set_position(.{ 400, 300 });
    self.sprite.set_scale(.{ 2, 2 });
    self.add_child(self.sprite, false, Godot.Node.INTERNAL_MODE_DISABLED);
}

pub fn onPressed(self: *Self) void {
    _ = self;
    std.debug.print("onPressed \n", .{});
}

pub fn onToggled(self: *Self, toggled_on: bool) void {
    _ = self;
    std.debug.print("onToggled {any}\n", .{toggled_on});
}
```
<img width="960" alt="example screenshot1" src="https://github.com/godot-zig/godot-zig/assets/90960/55cddaf9-18a9-4f15-97e1-669d80e9c34f">
<img width="960" alt="example screenshot2" src="https://github.com/godot-zig/godot-zig/assets/90960/aea7ab54-3e72-4d6b-b370-01862f9e91e0">


## Have fun!

