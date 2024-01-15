# godot-zig
Zig bindings for Godot 4

## Prerequisites:
1. zig master build
2. godot 4.2+
3. make sure godot is in your $PATH ( 'godot --version' works)

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
<img width="640" alt="example screenshot" src="https://github.com/godot-zig/godot-zig/assets/90960/2f37cb42-0433-4a1a-8046-9ed353beea74">
<a href="http://www.youtube.com/watch?feature=player_embedded&v=tKkMT7AOdRM" 
target="_blank"><img src="http://img.youtube.com/vi/tKkMT7AOdRM/0.jpg" 
alt="godot-zig example"
width="640" height="480" border="0" /></a>
## Have fun!
