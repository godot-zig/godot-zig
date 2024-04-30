const std = @import("std");
const Godot = @import("Godot.zig");
const GDE = Godot.GDE;
const Self = @This();
const Variant = Godot.Variant;
const precision = @import("build_options").precision;
const size = if (std.mem.eql(u8, precision, "double")) 40 else 24;

value: [size]u8,

const Type = c_int;
const TYPE_NIL: c_int = 0;
const TYPE_BOOL: c_int = 1;
const TYPE_INT: c_int = 2;
const TYPE_FLOAT: c_int = 3;
const TYPE_STRING: c_int = 4;
const TYPE_VECTOR2: c_int = 5;
const TYPE_VECTOR2I: c_int = 6;
const TYPE_RECT2: c_int = 7;
const TYPE_RECT2I: c_int = 8;
const TYPE_VECTOR3: c_int = 9;
const TYPE_VECTOR3I: c_int = 10;
const TYPE_TRANSFORM2D: c_int = 11;
const TYPE_VECTOR4: c_int = 12;
const TYPE_VECTOR4I: c_int = 13;
const TYPE_PLANE: c_int = 14;
const TYPE_QUATERNION: c_int = 15;
const TYPE_AABB: c_int = 16;
const TYPE_BASIS: c_int = 17;
const TYPE_TRANSFORM3D: c_int = 18;
const TYPE_PROJECTION: c_int = 19;
const TYPE_COLOR: c_int = 20;
const TYPE_STRING_NAME: c_int = 21;
const TYPE_NODE_PATH: c_int = 22;
const TYPE_RID: c_int = 23;
const TYPE_OBJECT: c_int = 24;
const TYPE_CALLABLE: c_int = 25;
const TYPE_SIGNAL: c_int = 26;
const TYPE_DICTIONARY: c_int = 27;
const TYPE_ARRAY: c_int = 28;
const TYPE_PACKED_BYTE_ARRAY: c_int = 29;
const TYPE_PACKED_INT32_ARRAY: c_int = 30;
const TYPE_PACKED_INT64_ARRAY: c_int = 31;
const TYPE_PACKED_FLOAT32_ARRAY: c_int = 32;
const TYPE_PACKED_FLOAT64_ARRAY: c_int = 33;
const TYPE_PACKED_STRING_ARRAY: c_int = 34;
const TYPE_PACKED_VECTOR2_ARRAY: c_int = 35;
const TYPE_PACKED_VECTOR3_ARRAY: c_int = 36;
const TYPE_PACKED_COLOR_ARRAY: c_int = 37;
const TYPE_MAX: c_int = 38;
const Operator = c_int;
const OP_EQUAL: c_int = 0;
const OP_NOT_EQUAL: c_int = 1;
const OP_LESS: c_int = 2;
const OP_LESS_EQUAL: c_int = 3;
const OP_GREATER: c_int = 4;
const OP_GREATER_EQUAL: c_int = 5;
const OP_ADD: c_int = 6;
const OP_SUBTRACT: c_int = 7;
const OP_MULTIPLY: c_int = 8;
const OP_DIVIDE: c_int = 9;
const OP_NEGATE: c_int = 10;
const OP_POSITIVE: c_int = 11;
const OP_MODULE: c_int = 12;
const OP_POWER: c_int = 13;
const OP_SHIFT_LEFT: c_int = 14;
const OP_SHIFT_RIGHT: c_int = 15;
const OP_BIT_AND: c_int = 16;
const OP_BIT_OR: c_int = 17;
const OP_BIT_XOR: c_int = 18;
const OP_BIT_NEGATE: c_int = 19;
const OP_AND: c_int = 20;
const OP_OR: c_int = 21;
const OP_XOR: c_int = 22;
const OP_NOT: c_int = 23;
const OP_IN: c_int = 24;
const OP_MAX: c_int = 25;
var from_type: [@as(usize, GDE.GDEXTENSION_VARIANT_TYPE_VARIANT_MAX)]GDE.GDExtensionVariantFromTypeConstructorFunc = undefined;
var to_type: [@as(usize, GDE.GDEXTENSION_VARIANT_TYPE_VARIANT_MAX)]GDE.GDExtensionTypeFromVariantConstructorFunc = undefined;
pub fn initBindings() void {
    for (1..TYPE_MAX) |i| {
        from_type[i] = Godot.getVariantFromTypeConstructor(@intCast(i));
        to_type[i] = Godot.getVariantToTypeConstructor(@intCast(i));
    }
}

fn getByGodotType(comptime T: type) Type {
    return switch (T) {
        Godot.String => GDE.GDEXTENSION_VARIANT_TYPE_STRING,
        Godot.Vector2 => GDE.GDEXTENSION_VARIANT_TYPE_VECTOR2,
        Godot.Vector2i => GDE.GDEXTENSION_VARIANT_TYPE_VECTOR2I,
        Godot.Rect2 => GDE.GDEXTENSION_VARIANT_TYPE_RECT2,
        Godot.Rect2i => GDE.GDEXTENSION_VARIANT_TYPE_RECT2I,
        Godot.Vector3 => GDE.GDEXTENSION_VARIANT_TYPE_VECTOR3,
        Godot.Vector3i => GDE.GDEXTENSION_VARIANT_TYPE_VECTOR3I,
        Godot.Transform2D => GDE.GDEXTENSION_VARIANT_TYPE_TRANSFORM2D,
        Godot.Vector4 => GDE.GDEXTENSION_VARIANT_TYPE_VECTOR4,
        Godot.Vector4i => GDE.GDEXTENSION_VARIANT_TYPE_VECTOR4I,
        Godot.Plane => GDE.GDEXTENSION_VARIANT_TYPE_PLANE,
        Godot.Quaternion => GDE.GDEXTENSION_VARIANT_TYPE_QUATERNION,
        Godot.AABB => GDE.GDEXTENSION_VARIANT_TYPE_AABB,
        Godot.Basis => GDE.GDEXTENSION_VARIANT_TYPE_BASIS,
        Godot.Transform3D => GDE.GDEXTENSION_VARIANT_TYPE_TRANSFORM3D,
        Godot.Projection => GDE.GDEXTENSION_VARIANT_TYPE_PROJECTION,

        Godot.Color => GDE.GDEXTENSION_VARIANT_TYPE_COLOR,
        Godot.StringName => GDE.GDEXTENSION_VARIANT_TYPE_STRING_NAME,
        Godot.NodePath => GDE.GDEXTENSION_VARIANT_TYPE_NODE_PATH,
        Godot.RID => GDE.GDEXTENSION_VARIANT_TYPE_RID,
        Godot.Object => GDE.GDEXTENSION_VARIANT_TYPE_OBJECT,
        Godot.Callable => GDE.GDEXTENSION_VARIANT_TYPE_CALLABLE,
        Godot.Signal => GDE.GDEXTENSION_VARIANT_TYPE_SIGNAL,
        Godot.Dictionary => GDE.GDEXTENSION_VARIANT_TYPE_DICTIONARY,
        Godot.Array => GDE.GDEXTENSION_VARIANT_TYPE_ARRAY,

        Godot.PackedByteArray => GDE.GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY,
        Godot.PackedInt32Array => GDE.GDEXTENSION_VARIANT_TYPE_PACKED_INT32_ARRAY,
        Godot.PackedInt64Array => GDE.GDEXTENSION_VARIANT_TYPE_PACKED_INT64_ARRAY,
        Godot.PackedFloat32Array => GDE.GDEXTENSION_VARIANT_TYPE_PACKED_FLOAT32_ARRAY,
        Godot.PackedFloat64Array => GDE.GDEXTENSION_VARIANT_TYPE_PACKED_FLOAT64_ARRAY,
        Godot.PackedStringArray => GDE.GDEXTENSION_VARIANT_TYPE_PACKED_STRING_ARRAY,
        Godot.PackedVector2Array => GDE.GDEXTENSION_VARIANT_TYPE_PACKED_VECTOR2_ARRAY,
        Godot.PackedVector3Array => GDE.GDEXTENSION_VARIANT_TYPE_PACKED_VECTOR3_ARRAY,
        Godot.PackedColorArray => GDE.GDEXTENSION_VARIANT_TYPE_PACKED_COLOR_ARRAY,
        else => GDE.GDEXTENSION_VARIANT_TYPE_NIL,
    };
}

fn getChildTypeOrSelf(comptime T: type) type {
    const typeInfo = @typeInfo(T);
    return switch (typeInfo) {
        .Pointer => |info| info.child,
        .Optional => |info| info.child,
        else => T,
    };
}
pub fn getVariantType(comptime T: type) Type {
    const typeInfo = @typeInfo(T);
    if (typeInfo == .Pointer and @typeInfo(typeInfo.Pointer.child) != .Struct) {
        @compileError("Init Variant from " ++ @typeName(T) ++ " is not supported");
    }
    const RT = getChildTypeOrSelf(T);

    const ret = comptime getByGodotType(RT);
    if (ret == GDE.GDEXTENSION_VARIANT_TYPE_NIL) {
        const ret1 = switch (@typeInfo(RT)) {
            .Struct => GDE.GDEXTENSION_VARIANT_TYPE_OBJECT,
            .Bool => GDE.GDEXTENSION_VARIANT_TYPE_BOOL,
            .Int, .ComptimeInt => GDE.GDEXTENSION_VARIANT_TYPE_INT,
            .Float, .ComptimeFloat => GDE.GDEXTENSION_VARIANT_TYPE_FLOAT,
            .Void => GDE.GDEXTENSION_VARIANT_TYPE_NIL,
            else => {
                @compileLog("Unknown variant type " ++ @typeName(T) ++ " " ++ @tagName(typeInfo) ++ " RT:" ++ @typeName(RT));
                return GDE.GDEXTENSION_VARIANT_TYPE_NIL;
            },
        };
        return ret1;
    }
    return ret;
}
pub fn init() Self {
    var result: Self = undefined;
    Godot.variantNewNil(&result);
    return result;
}
pub fn initFrom(from: anytype) Self {
    const tid = comptime getVariantType(@TypeOf(from));
    var result: Self = undefined;
    from_type[@intCast(tid)].?(@ptrCast(&result), @ptrCast(@constCast(&from)));
    return result;
}
pub fn as(self: Self, comptime T: type) T {
    const tid = comptime getVariantType(T);
    if (tid == GDE.GDEXTENSION_VARIANT_TYPE_OBJECT) {
        var obj: ?*anyopaque = null;
        to_type[GDE.GDEXTENSION_VARIANT_TYPE_OBJECT].?(@ptrCast(&obj), @ptrCast(&self.value));
        const godotObj: *Godot.Object = @ptrCast(@alignCast(Godot.getObjectInstanceBinding(obj)));
        const RealType = @typeInfo(T).Pointer.child;
        if (RealType == Godot.Object) {
            return godotObj;
        } else {
            const classTag = Godot.classdbGetClassTag(@ptrCast(Godot.getClassName(RealType)));
            const casted = Godot.objectCastTo(godotObj.godot_object, classTag);
            return @ptrCast(@alignCast(Godot.getObjectInstanceBinding(casted)));
        }
    }

    var result: T = undefined;
    to_type[@intCast(tid)].?(@ptrCast(&result), @ptrCast(@constCast(&self.value)));
    return result;
}
