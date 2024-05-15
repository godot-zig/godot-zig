const std = @import("std");

const precision = @import("build_options").precision;
const real_t = if (@import("std").mem.eql(u8, precision, "double")) f64 else f32;

pub const Vector2 = Vec2(real_t);
pub const Vector2i = Vec2(i32);
pub const Vector3 = Vec3(real_t);
pub const Vector3i = Vec3(i32);
pub const Vector4 = Vec4(real_t);
pub const Vector4i = Vec4(i32);

pub fn VecMethods(comptime T: type, comptime N: u8, comptime Self: type) type {
    return struct {
        const A = [N]T;
        pub inline fn asArray(self: Self) A {
            return @bitCast(self);
        }
        pub inline fn fromArray(a: A) Self {
            return @bitCast(a);
        }

        const Simd = @Vector(N, T);
        pub inline fn asSimd(self: Self) Simd {
            return @as(Simd, @bitCast(self));
        }
        pub inline fn fromSimd(v: Simd) Self {
            return @bitCast(@as(A, v));
        }

        pub fn add(self: Self, other: Self) Self {
            return fromSimd(self.asSimd() + other.asSimd());
        }

        pub fn sub(self: Self, other: Self) Self {
            return fromSimd(self.asSimd() - other.asSimd());
        }

        pub fn mul(self: Self, other: Self) Self {
            return fromSimd(self.asSimd() * other.asSimd());
        }

        pub fn div(self: Self, other: Self) Self {
            return fromSimd(self.asSimd() / other.asSimd());
        }

        pub fn scale(self: Self, scalar: T) Self {
            return fromSimd(self.asSimd() * @as(Simd, @splat(scalar)));
        }

        pub fn len(self: Self) T {
            return @sqrt(@reduce(.Add, self.asSimd() * self.asSimd()));
        }

        pub fn len2(self: Self) T {
            return @reduce(.Add, self.asSimd() * self.asSimd());
        }

        pub fn dot(self: Self, other: Self) T {
            return @reduce(.Add, self.asSimd() * other.asSimd());
        }

        pub fn norm(self: Self) Self {
            return self.scale(1 / self.len());
        }

        pub fn eq(self: Self, other: Self) bool {
            return @reduce(.And, self.asSimd() == other.asSimd());
        }

        pub fn zero() Self {
            return fromArray([1]T{0} ** N);
        }

        pub fn one() Self {
            return fromArray([1]T{1} ** N);
        }

        pub fn set(scalar: T) Self {
            return fromArray([1]T{scalar} ** N);
        }

        pub fn negate(self: Self) Self {
            return self.scale(-1);
        }
    };
}

pub const VectorComponent = enum { x, y, z, w };

pub fn Vec2(comptime T: type) type {
    return extern struct {
        x: T,
        y: T,

        const Self = @This();
        const Methods = VecMethods(T, 2, Self);

        pub inline fn new(x: T, y: T) Self {
            return .{
                .x = x,
                .y = y,
            };
        }
        pub inline fn swizzle(self: Self, xc: VectorComponent, yc: VectorComponent) Self {
            return Methods.fromSimd(@shuffle(T, self.asSimd(), undefined, [2]T{
                @intFromEnum(xc),
                @intFromEnum(yc),
            }));
        }

        pub fn cross(self: Self, other: Self) T {
            return @reduce(.Sub, self.mul(other.swizzle(.y, .x)));
        }

        pub fn angle(self: Self, other: Self) T {
            return std.math.atan2(self.cross(other), self.dot(other));
        }

        pub usingnamespace Methods;
    };
}

pub fn Vec3(comptime T: type) type {
    return extern struct {
        x: T,
        y: T,
        z: T,

        const Self = @This();
        const Methods = VecMethods(T, 3, Self);

        pub fn new(x: T, y: T, z: T) Self {
            return .{
                .x = x,
                .y = y,
                .z = z,
            };
        }
        pub inline fn swizzle(self: Self, xc: VectorComponent, yc: VectorComponent, zc: VectorComponent) Self {
            return Methods.fromSimd(@shuffle(T, self.asSimd(), undefined, [3]T{
                @intFromEnum(xc),
                @intFromEnum(yc),
                @intFromEnum(zc),
            }));
        }

        pub fn cross(self: Self, other: Self) Self {
            return self.swizzle(.y, .z, .x).mul(other.swizzle(.z, .x, .y))
                .sub(self.swizzle(.z, .x, .y).mul(other.swizzle(.y, .z, .x)));
        }

        pub fn angle(self: Self, other: Self) T {
            return std.math.atan2(self.cross(other).len(), self.dot(other));
        }

        pub usingnamespace Methods;
    };
}

pub fn Vec4(comptime T: type) type {
    return extern struct {
        x: T,
        y: T,
        z: T,
        w: T,

        const Self = @This();
        const Methods = VecMethods(T, 4, Self);

        pub fn new(x: T, y: T, z: T, w: T) Self {
            return .{
                .x = x,
                .y = y,
                .z = z,
                .w = w,
            };
        }

        pub inline fn swizzle(self: Self, xc: VectorComponent, yc: VectorComponent, zc: VectorComponent, wc: VectorComponent) Self {
            return Methods.fromSimd(@shuffle(T, self.asSimd(), undefined, [4]T{
                @intFromEnum(xc),
                @intFromEnum(yc),
                @intFromEnum(zc),
                @intFromEnum(wc),
            }));
        }

        pub usingnamespace Methods;
    };
}
