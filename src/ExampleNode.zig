const std = @import("std");
const Godot = @import("godot");
const Vector2 = Godot.Vector2;
const SpritesNode = @import("SpriteNode.zig");
const GuiNode = @import("GuiNode.zig");
const SignalNode = @import("SignalNode.zig");
const Examples = [_]struct { name: [:0]const u8, T: type }{
    .{ .name = "Sprites", .T = SpritesNode },
    .{ .name = "GUI", .T = GuiNode },
    .{ .name = "Signals", .T = SignalNode },
};

const Self = @This();
pub usingnamespace Godot.Node;
godot_object: *Godot.Node,

panel: *Godot.PanelContainer = undefined,
example_node: ?Godot.Node = null,

property1: Godot.Vector3 = Godot.Vector3{ 42, 42, 42 },
property2: Godot.Vector3 = Godot.Vector3{ 24, 24, 24 },

const property1_name: [:0]const u8 = "Property1";
const property2_name: [:0]const u8 = "Property2";

fn clearScene(self: *Self) void {
    if (self.example_node) |n| {
        n.queue_free();
        self.example_node = null;
    }
}

pub fn onTimeout(_: *Self) void {
    std.debug.print("onTimeout\n", .{});
}

pub fn onResized(_: *Self) void {
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
    inline for (Examples) |E| {
        Godot.registerClass(E.T);
    }

    //initialize fields
    self.example_node = null;
    self.property1 = Godot.Vector3{ 111, 111, 111 };
    self.property2 = Godot.Vector3{ 222, 222, 222 };

    if (Godot.Engine.getSingleton().is_editor_hint()) return;

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
        if (!Godot.Engine.getSingleton().is_editor_hint()) {
            self.get_tree().quit(0);
        }
    }
}

pub fn _get_property_list(_: *Self) []const Godot.PropertyInfo {
    const C = struct {
        var properties: [32]Godot.PropertyInfo = undefined;
    };

    C.properties[0] = Godot.PropertyInfo.init(Godot.GDE.GDEXTENSION_VARIANT_TYPE_VECTOR3, Godot.StringName.initFromLatin1Chars(property1_name));
    C.properties[1] = Godot.PropertyInfo.init(Godot.GDE.GDEXTENSION_VARIANT_TYPE_VECTOR3, Godot.StringName.initFromLatin1Chars(property2_name));

    return C.properties[0..2];
}

pub fn _property_can_revert(_: *Self, name: Godot.StringName) bool {
    if (name.casecmp_to(property1_name) == 0) {
        return true;
    } else if (name.casecmp_to(property2_name) == 0) {
        return true;
    }

    return false;
}

pub fn _property_get_revert(_: *Self, name: Godot.StringName, value: *Godot.Variant) bool {
    if (name.casecmp_to(property1_name) == 0) {
        value.* = Godot.Variant.initFrom(Godot.Vector3{ 42, 42, 42 });
        return true;
    } else if (name.casecmp_to(property2_name) == 0) {
        value.* = Godot.Variant.initFrom(Godot.Vector3{ 24, 24, 24 });
        return true;
    }

    return false;
}

pub fn _set(self: *Self, name: Godot.StringName, value: Godot.Variant) bool {
    if (name.casecmp_to(property1_name) == 0) {
        self.property1 = value.as(Godot.Vector3);
        return true;
    } else if (name.casecmp_to(property2_name) == 0) {
        self.property2 = value.as(Godot.Vector3);
        return true;
    }

    return false;
}

pub fn _get(self: *Self, name: Godot.StringName, value: *Godot.Variant) bool {
    if (name.casecmp_to(property1_name) == 0) {
        value.* = Godot.Variant.initFrom(self.property1);
        return true;
    } else if (name.casecmp_to(property2_name) == 0) {
        value.* = Godot.Variant.initFrom(self.property2);
        return true;
    }

    return false;
}

pub fn _to_string(_: *Self) ?Godot.String {
    return Godot.String.initFromLatin1Chars("ExampleNode");
}
