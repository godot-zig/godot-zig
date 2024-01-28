const std = @import("std");
const Godot = @import("api/Godot.zig");
const Vector2 = Godot.Vector2;
const SpritesNode = @import("SpriteNode.zig");
const GuiNode = @import("GuiNode.zig");

const Examples = [_]struct { name: []const u8, T: type }{
    .{ .name = "Sprites", .T = SpritesNode },
    .{ .name = "GUI", .T = GuiNode },
};

const Self = @This();
pub usingnamespace Godot.Node;
godot_object: *Godot.Node,

panel: *Godot.PanelContainer = undefined,
example_node: ?Godot.Node = null,

fn clearScene(self: *Self) void {
    if (self.example_node) |n| {
        n.queue_free();
        self.example_node = null;
    }
}

pub fn onTimeout(self: *Self) void {
    _ = self;
    std.debug.print("onTimeout\n", .{});
}

pub fn onResized(self: *Self) void {
    _ = self; // autofix

    std.debug.print("onResized\n", .{});
}

pub fn on_item_focused(self: *Self, idx: i64) void {
    self.clearScene();
    switch (idx) {
        inline 0...Examples.len - 1 => |i| {
            const n = Godot.create(Examples[i].T) catch unreachable;
            self.example_node = .{ .godot_object = n.godot_object }; //Godot classes in gdextension are just wrappers around a native pointer (godot_object in GodotZig).
            self.panel.add_child(self.example_node, false, Godot.Node.INTERNAL_MODE_DISABLED);
            self.panel.grab_focus();
        },
        else => {},
    }
}

pub fn _enter_tree(self: *Self) void {
    Godot.registerClass(SpritesNode);
    Godot.registerClass(GuiNode);

    if (Godot.Engine.getSingleton().is_editor_hint()) return;
    //initialize fields
    self.example_node = null;

    const window_size = self.get_tree().get_root().get_size();
    var sp = Godot.HSplitContainer.newHSplitContainer();
    sp.set_h_size_flags(Godot.Control.SIZE_EXPAND_FILL);
    sp.set_v_size_flags(Godot.Control.SIZE_EXPAND_FILL);
    sp.set_split_offset(@intFromFloat(@as(f32, @floatFromInt(window_size[0])) * 0.2));
    sp.set_anchors_preset(Godot.Control.PRESET_FULL_RECT, false);
    var itemList = Godot.ItemList.newItemList();
    inline for (0..Examples.len) |i| {
        _ = itemList.add_item(Examples[i].name, null, true);
    }
    var timer = self.get_tree().create_timer(1.0, true, false, false);
    defer _ = timer.unreference();

    Godot.connect(timer, "timeout", self, "onTimeout");
    Godot.connect(sp, "resized", self, "onResized");

    Godot.connect(itemList, "item_selected", self, "on_item_focused");
    self.panel = Godot.PanelContainer.newPanelContainer();
    self.panel.set_h_size_flags(Godot.Control.SIZE_FILL);
    self.panel.set_v_size_flags(Godot.Control.SIZE_FILL);
    self.panel.set_focus_mode(Godot.Control.FOCUS_ALL);
    sp.add_child(itemList, false, Godot.Node.INTERNAL_MODE_DISABLED);
    sp.add_child(self.panel, false, Godot.Node.INTERNAL_MODE_DISABLED);
    self.add_child(sp, false, Godot.Node.INTERNAL_MODE_DISABLED);
}

pub fn _exit_tree(self: *Self) void {
    _ = self;
    Godot.Engine.releaseSingleton();
}

pub fn _notification(self: *Self, what: i32) void {
    if (what == Godot.Node.NOTIFICATION_WM_CLOSE_REQUEST) {
        self.get_tree().quit(0);
    }
}
