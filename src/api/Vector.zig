const math = @import("std").math;

const precision = @import("build_options").precision;
const real_t = if (@import("std").mem.eql(u8, precision, "double")) f64 else f32;

pub const Vector2 = @Vector(2, real_t);
pub const Vector2i = @Vector(2, i32);
pub const Vector3 = @Vector(3, real_t);
pub const Vector3i = @Vector(3, i32);
pub const Vector4 = @Vector(4, real_t);
pub const Vector4i = @Vector(4, i32);

pub fn len2(v: anytype) @TypeOf(v[0]) {
    switch (@typeInfo(@TypeOf(v)).Vector.len) {
        inline 2 => {
            return v[0] * v[0] + v[1] * v[1];
        },
        inline 3 => {
            return v[0] * v[0] + v[1] * v[1] + v[2] * v[2];
        },
        inline 4 => {
            return v[0] * v[0] + v[1] * v[1] + v[2] * v[2] + v[3] * v[3];
        },
        else => {
            @compileError("only Vectors with length 2, 3 or 4 are supported!");
        },
    }
}

pub fn len(v: anytype) @TypeOf(v[0]) {
    return @sqrt(len2(v));
}

pub fn normalized(v: anytype) @TypeOf(v) {
    return v / @as(@TypeOf(v), @splat(len(v)));
}

pub fn mulScalar(v: anytype, s: @TypeOf(v[0])) @TypeOf(v) {
    return v * @as(@TypeOf(v), @splat(s));
}
