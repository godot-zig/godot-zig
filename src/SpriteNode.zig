const std = @import("std");
const Godot = @import("godot");
const Vector2 = Godot.Vector2;
const Sprite = struct {
    pos: Godot.Vector2,
    vel: Godot.Vector2,
    scale: Godot.Vector2,
    gd_sprite: *Godot.Sprite2D,
};
const Self = @This();
pub usingnamespace Godot.Control;
godot_object: *Godot.Control,

sprites: std.ArrayList(Sprite) = undefined,

pub fn newSpritesNode() *Self {
    var self = Godot.create(Self);
    self.example_node = null;
}

pub fn _ready(self: *Self) void {
    if (Godot.Engine.getSingleton().is_editor_hint()) return;

    self.sprites = std.ArrayList(Sprite).init(Godot.general_allocator);
    const rnd = Godot.RandomNumberGenerator.newRandomNumberGenerator();
    defer _ = Godot.unreference(rnd);

    const resource_loader = Godot.ResourceLoader.getSingleton();
    const tex: *Godot.Texture2D = @ptrCast(resource_loader.load("res://textures/logo.png", "", Godot.ResourceLoader.CACHE_MODE_REUSE));
    defer _ = Godot.unreference(tex);
    const sz = self.get_parent_area_size();

    for (0..10000) |_| {
        const s: f32 = @floatCast(rnd.randf_range(0.1, 0.2));
        const spr = Sprite{
            .pos = Godot.Vector2{ @floatCast(rnd.randf_range(0, sz[0])), @floatCast(rnd.randf_range(0, sz[1])) },
            .vel = Godot.Vector2{ @floatCast(rnd.randf_range(-1000, 1000)), @floatCast(rnd.randf_range(-1000, 1000)) },
            .scale = Godot.Vector2{ s, s },
            .gd_sprite = Godot.Sprite2D.newSprite2D(),
        };
        spr.gd_sprite.set_texture(tex);
        spr.gd_sprite.set_rotation(rnd.randf_range(0, 3.14));
        spr.gd_sprite.set_scale(spr.scale);
        self.add_child(spr.gd_sprite, false, Godot.Node.INTERNAL_MODE_DISABLED);
        self.sprites.append(spr) catch unreachable;
    }
}

pub fn _exit_tree(self: *Self) void {
    self.sprites.deinit();
    Godot.Engine.releaseSingleton();
    Godot.ResourceLoader.releaseSingleton();
}

pub fn _physics_process(self: *Self, delta: f64) void {
    const sz = self.get_parent_area_size(); //get_size();

    for (self.sprites.items) |*spr| {
        const pos = spr.pos + spr.vel * Vector2{ @floatCast(delta), @floatCast(delta) };
        const spr_size = spr.gd_sprite.get_rect().get_size() * spr.gd_sprite.get_scale();

        if (pos[0] <= spr_size[0] / 2) {
            spr.vel[0] = @abs(spr.vel[0]);
        } else if (pos[0] >= sz[0] - spr_size[0] / 2) {
            spr.vel[0] = -@abs(spr.vel[0]);
        }
        if (pos[1] <= spr_size[1] / 2) {
            spr.vel[1] = @abs(spr.vel[1]);
        } else if (pos[1] >= sz[1] - spr_size[1] / 2) {
            spr.vel[1] = -@abs(spr.vel[1]);
        }
        spr.pos = pos;
        spr.gd_sprite.set_position(spr.pos);
    }
}
