const std = @import("std");
pub const Variant = @import("Variant.zig");
pub usingnamespace @import("Vector.zig");
pub const UtilityFunctions = @import("gen").UtilityFunctions;
const GD = @import("gen").GodotCore;
const GDE = GD.GDE;
const StringName = GD.StringName;
const String = GD.String;
pub usingnamespace GD;

pub var dummy_callbacks = GDE.GDExtensionInstanceBindingCallbacks{ .create_callback = instanceBindingCreateCallback, .free_callback = instanceBindingFreeCallback, .reference_callback = instanceBindingReferenceCallback };
pub fn instanceBindingCreateCallback(_: ?*anyopaque, _: ?*anyopaque) callconv(.C) ?*anyopaque {
    return null;
}
pub fn instanceBindingFreeCallback(_: ?*anyopaque, _: ?*anyopaque, _: ?*anyopaque) callconv(.C) void {}
pub fn instanceBindingReferenceCallback(_: ?*anyopaque, _: ?*anyopaque, _: GDE.GDExtensionBool) callconv(.C) GDE.GDExtensionBool {
    return 1;
}

pub fn getObjectInstanceBinding(obj: GDE.GDExtensionObjectPtr) ?*anyopaque {
    const retobj = GD.objectGetInstanceBinding(obj, GD.p_library, null);
    if (retobj) |r| {
        return @ptrCast(r);
    }

    var class_name: StringName = undefined;
    var callbacks: ?*GDE.GDExtensionInstanceBindingCallbacks = null;
    if (GD.objectGetClassName(obj, GD.p_library, @ptrCast(&class_name)) == 1) {
        callbacks = GD.callback_map.get(class_name);
    }
    if (callbacks == null) {
        callbacks = &GD.Object.callbacks_Object;
    }
    return GD.objectGetInstanceBinding(obj, GD.p_library, @ptrCast(callbacks));
}

pub fn unreference(refcounted_obj: anytype) void {
    if (refcounted_obj.unreference()) {
        GD.objectDestroy(refcounted_obj.godot_object);
    }
}

pub fn getClassName(comptime T: type) *StringName {
    const C = struct {
        pub fn makeItUniqueForT() i8 {
            return @sizeOf(T);
        }
        pub var class_name: StringName = undefined;
    };
    return &C.class_name;
}

pub fn getParentClassName(comptime T: type) *StringName {
    const C = struct {
        pub fn makeItUniqueForT() i8 {
            return @sizeOf(T);
        }
        pub var parent_class_name: StringName = undefined;
    };
    return &C.parent_class_name;
}

pub fn stringNameToAscii(strname: StringName, buf: []u8) []const u8 {
    const str = String.initFromStringName(strname);
    return stringToAscii(str, buf);
}

pub fn stringToAscii(str: String, buf: []u8) []const u8 {
    const sz = GD.stringToLatin1Chars(@ptrCast(&str), &buf[0], @intCast(buf.len));
    return buf[0..@intCast(sz)];
}

fn getBaseName(str: [:0]const u8) [:0]const u8 {
    const pos = std.mem.lastIndexOfScalar(u8, str, '.') orelse return str;
    return str[pos + 1 ..];
}

const max_align_t = c_longdouble;
const SIZE_OFFSET: usize = 0;
const ELEMENT_OFFSET = if ((SIZE_OFFSET + @sizeOf(u64)) % @alignOf(u64) == 0) (SIZE_OFFSET + @sizeOf(u64)) else ((SIZE_OFFSET + @sizeOf(u64)) + @alignOf(u64) - ((SIZE_OFFSET + @sizeOf(u64)) % @alignOf(u64)));
const DATA_OFFSET = if ((ELEMENT_OFFSET + @sizeOf(u64)) % @alignOf(max_align_t) == 0) (ELEMENT_OFFSET + @sizeOf(u64)) else ((ELEMENT_OFFSET + @sizeOf(u64)) + @alignOf(max_align_t) - ((ELEMENT_OFFSET + @sizeOf(u64)) % @alignOf(max_align_t)));

pub fn alloc(size: u32) ?*u8 {
    if (@import("builtin").mode == .Debug) {
        const p = @as([*c]u8, @ptrCast(GD.memAlloc(size)));
        return p;
    } else {
        const p = @as([*c]u8, @ptrCast(GD.memAlloc(size + DATA_OFFSET)));
        return @ptrCast(&p[DATA_OFFSET]);
    }
}

pub fn free(ptr: ?*anyopaque) void {
    if (ptr) |p| {
        GD.memFree(p);
    }
}

pub fn create(comptime T: type) !*T {
    const self = try GD.general_allocator.create(T);

    //warning: every field of T other than godot_object must have a default value.
    //todo: get rid of this limitation
    self.* = T{
        .godot_object = @ptrCast(@alignCast(GD.classdbConstructObject(@ptrCast(getParentClassName(T))))),
    };
    GD.objectSetInstance(self.godot_object, @ptrCast(getClassName(T)), @ptrCast(self));
    GD.objectSetInstanceBinding(self.godot_object, GD.p_library, @ptrCast(self), @ptrCast(&dummy_callbacks));
    return self;
}

pub fn destroy(instance: anytype) void {
    if (@hasField(std.meta.Child(@TypeOf(instance)), "godot_object")) {
        GD.objectFreeInstanceBinding(instance.godot_object, GD.p_library);
        GD.objectDestroy(instance.godot_object);
    } else {
        GD.general_allocator.destroy(instance);
    }
}

var registered_classes: std.StringHashMap(bool) = undefined;
pub fn registerClass(comptime T: type) void {
    //prevent duplicate registration
    if (registered_classes.contains(@typeName(T))) return;
    registered_classes.put(@typeName(T), true) catch unreachable;

    const P = @typeInfo(std.meta.FieldType(T, .godot_object)).Pointer.child;
    const parent_class_name: [:0]const u8 = comptime getBaseName(@typeName(P));
    getParentClassName(T).* = StringName.initFromLatin1Chars(parent_class_name);
    getClassName(T).* = StringName.initFromLatin1Chars(getBaseName(@typeName(T)));

    const PerClassData = struct {
        pub var class_info = init_blk: {
            const ClassInfo: struct { T: type, version: i8 } = if (@hasDecl(GDE, "GDExtensionClassCreationInfo3"))
                .{ .T = GDE.GDExtensionClassCreationInfo3, .version = 3 }
            else if (@hasDecl(GDE, "GDExtensionClassCreationInfo2"))
                .{ .T = GDE.GDExtensionClassCreationInfo2, .version = 2 }
            else
                @compileError("Godot 4.2 or higher is required.");
            var c: ClassInfo.T = .{
                .is_virtual = 0,
                .is_abstract = 0,
                .is_exposed = 1,
                .set_func = if (@hasDecl(T, "_set")) set_bind else null,
                .get_func = if (@hasDecl(T, "_get")) get_bind else null,
                .get_property_list_func = if (@hasDecl(T, "_get_property_list")) get_property_list_bind else null,
                .free_property_list_func = free_property_list_bind,
                .property_can_revert_func = if (@hasDecl(T, "_property_can_revert")) property_can_revert_bind else null,
                .property_get_revert_func = if (@hasDecl(T, "_property_get_revert")) property_get_revert_bind else null,
                .validate_property_func = if (@hasDecl(T, "_validate_property")) validate_property_bind else null,
                .notification_func = if (@hasDecl(T, "_notification")) notification_bind else null,
                .to_string_func = if (@hasDecl(T, "_to_string")) to_string_bind else null,
                .reference_func = null,
                .unreference_func = null,
                .create_instance_func = create_instance_bind, // (Default) constructor; mandatory. If the class is not instantiable, consider making it virtual or abstract.
                .free_instance_func = free_instance_bind, // Destructor; mandatory.
                .get_virtual_func = get_virtual_bind, // Queries a virtual function by name and returns a callback to invoke the requested virtual function.
                .get_virtual_call_data_func = null,
                .call_virtual_with_data_func = null,
                .get_rid_func = null,
                .class_userdata = @ptrCast(getClassName(T)), // Per-class user data, later accessible in instance bindings.
            };
            if (ClassInfo.version >= 3) {
                c.is_runtime = 0;
            }
            break :init_blk c;
        };

        pub fn set_bind(p_instance: GDE.GDExtensionClassInstancePtr, name: GDE.GDExtensionConstStringNamePtr, value: GDE.GDExtensionConstVariantPtr) callconv(.C) GDE.GDExtensionBool {
            if (p_instance) |p| {
                return if (T._set(@ptrCast(@alignCast(p)), @as(*StringName, @ptrCast(@constCast(name))).*, @as(*Variant, @ptrCast(@constCast(value))).*)) 1 else 0; //fn _set(_: *Self, name: Godot.StringName, _: Godot.Variant) bool
            } else {
                return 0;
            }
        }

        pub fn get_bind(p_instance: GDE.GDExtensionClassInstancePtr, name: GDE.GDExtensionConstStringNamePtr, value: GDE.GDExtensionVariantPtr) callconv(.C) GDE.GDExtensionBool {
            if (p_instance) |p| {
                return if (T._get(@ptrCast(@alignCast(p)), @as(*StringName, @ptrCast(@constCast(name))).*, @as(*Variant, @ptrCast(value)))) 1 else 0; //fn _get(self:*Self, name: StringName, value:*Variant) bool
            } else {
                return 0;
            }
        }
        pub fn get_property_list_bind(p_instance: GDE.GDExtensionClassInstancePtr, r_count: [*c]u32) callconv(.C) [*c]const GDE.GDExtensionPropertyInfo {
            if (p_instance) |p| {
                const ptr: *T = @ptrCast(@alignCast(p));
                const property_list = T._get_property_list(ptr);

                const count: u32 = @intCast(property_list.len);

                const propertyies = @as([*c]GDE.GDExtensionPropertyInfo, @ptrCast(@alignCast(alloc(@sizeOf(GDE.GDExtensionPropertyInfo) * count))));
                for (property_list, 0..) |*property, i| {
                    propertyies[i].type = property.type;
                    propertyies[i].hint = property.hint;
                    propertyies[i].usage = property.usage;
                    propertyies[i].name = @ptrCast(@constCast(&property.name.value));
                    propertyies[i].class_name = @ptrCast(@constCast(&property.class_name.value));
                    propertyies[i].hint_string = @ptrCast(@constCast(&property.hint_string.value));
                }
                if (r_count) |r| {
                    r.* = count;
                }
                return propertyies;
            } else {
                if (r_count) |r| {
                    r.* = 0;
                }
                return null;
            }
        }
        pub fn free_property_list_bind(p_instance: GDE.GDExtensionClassInstancePtr, p_list: [*c]const GDE.GDExtensionPropertyInfo) callconv(.C) void {
            if (@hasDecl(T, "_free_property_list")) {
                if (p_instance) |p| {
                    T._free_property_list(@ptrCast(@alignCast(p)), p_list); //fn _free_property_list(self:*Self, p_list:[*c]const GDE.GDExtensionPropertyInfo) void {}
                }
            }
            if (p_list) |list| {
                free(@ptrCast(@constCast(list)));
            }
        }
        pub fn property_can_revert_bind(p_instance: GDE.GDExtensionClassInstancePtr, p_name: GDE.GDExtensionConstStringNamePtr) callconv(.C) GDE.GDExtensionBool {
            if (p_instance) |p| {
                return if (T._property_can_revert(@ptrCast(@alignCast(p)), @as(*StringName, @ptrCast(@constCast(p_name))).*)) 1 else 0; //fn _property_can_revert(self:*Self, name: StringName) bool
            } else {
                return 0;
            }
        }
        pub fn property_get_revert_bind(p_instance: GDE.GDExtensionClassInstancePtr, p_name: GDE.GDExtensionConstStringNamePtr, r_ret: GDE.GDExtensionVariantPtr) callconv(.C) GDE.GDExtensionBool {
            if (p_instance) |p| {
                return if (T._property_get_revert(@ptrCast(@alignCast(p)), @as(*StringName, @ptrCast(@constCast(p_name))).*, @as(*Variant, @ptrCast(r_ret)))) 1 else 0; //fn _property_get_revert(self:*Self, name: StringName, ret:*Variant) bool
            } else {
                return 0;
            }
        }
        pub fn validate_property_bind(p_instance: GDE.GDExtensionClassInstancePtr, p_property: [*c]GDE.GDExtensionPropertyInfo) callconv(.C) GDE.GDExtensionBool {
            if (p_instance) |p| {
                return if (T._validate_property(@ptrCast(@alignCast(p)), p_property)) 1 else 0; //fn _validate_property(self:*Self, p_property: [*c]GDE.GDExtensionPropertyInfo) bool
            } else {
                return 0;
            }
        }
        pub fn notification_bind(p_instance: GDE.GDExtensionClassInstancePtr, p_what: i32, _: GDE.GDExtensionBool) callconv(.C) void {
            if (p_instance) |p| {
                T._notification(@ptrCast(@alignCast(p)), p_what); //fn _notification(self:*Self, what:i32) void
            }
        }
        pub fn to_string_bind(p_instance: GDE.GDExtensionClassInstancePtr, r_is_valid: [*c]GDE.GDExtensionBool, p_out: GDE.GDExtensionStringPtr) callconv(.C) void {
            if (p_instance) |p| {
                const ret: ?String = T._to_string(@ptrCast(@alignCast(p))); //fn _to_string(self:*Self) ?Godot.String {}
                if (ret) |r| {
                    r_is_valid.* = 1;
                    @as(*String, @ptrCast(p_out)).* = r;
                }
            }
        }
        pub fn reference_bind(p_instance: GDE.GDExtensionClassInstancePtr) callconv(.C) void {
            T._reference(@ptrCast(@alignCast(p_instance)));
        }
        pub fn unreference_bind(p_instance: GDE.GDExtensionClassInstancePtr) callconv(.C) void {
            T._unreference(@ptrCast(@alignCast(p_instance)));
        }
        pub fn create_instance_bind(p_userdata: ?*anyopaque) callconv(.C) GDE.GDExtensionObjectPtr {
            _ = p_userdata;
            const ret = create(T) catch unreachable;
            return @ptrCast(ret.godot_object);
        }
        pub fn free_instance_bind(p_userdata: ?*anyopaque, p_instance: GDE.GDExtensionClassInstancePtr) callconv(.C) void {
            GD.general_allocator.destroy(@as(*T, @ptrCast(@alignCast(p_instance))));
            _ = p_userdata;
        }
        pub fn get_virtual_bind(p_userdata: ?*anyopaque, p_name: GDE.GDExtensionConstStringNamePtr) callconv(.C) GDE.GDExtensionClassCallVirtual {
            const virtual_bind = @field(T, "get_virtual_" ++ parent_class_name);
            return virtual_bind(T, p_userdata, p_name);
        }
        pub fn get_rid_bind(p_instance: GDE.GDExtensionClassInstancePtr) callconv(.C) u64 {
            return T._get_rid(@ptrCast(@alignCast(p_instance)));
        }
    };
    const classdbRegisterExtensionClass = if (@hasDecl(GD, "classdbRegisterExtensionClass3"))
        GD.classdbRegisterExtensionClass3
    else if (@hasDecl(GD, "classdbRegisterExtensionClass2"))
        GD.classdbRegisterExtensionClass2
    else
        @compileError("Godot 4.2 or higher is required.");
    classdbRegisterExtensionClass(@ptrCast(GD.p_library), @ptrCast(getClassName(T)), @ptrCast(getParentClassName(T)), @ptrCast(&PerClassData.class_info));
    if (@hasDecl(T, "_bind_methods")) {
        T._bind_methods();
    }
}

pub fn MethodBinderT(comptime MethodType: type) type {
    return struct {
        const ReturnType = @typeInfo(MethodType).Fn.return_type;
        const ArgCount = @typeInfo(MethodType).Fn.params.len;
        const ArgsTuple = std.meta.fields(std.meta.ArgsTuple(MethodType));
        var arg_properties: [ArgCount + 1]GDE.GDExtensionPropertyInfo = undefined;
        var arg_metadata: [ArgCount + 1]GDE.GDExtensionClassMethodArgumentMetadata = undefined;
        var method_name: StringName = undefined;
        var method_info: GDE.GDExtensionClassMethodInfo = undefined;

        pub fn bind_call(p_method_userdata: ?*anyopaque, p_instance: GDE.GDExtensionClassInstancePtr, p_args: [*c]const GDE.GDExtensionConstVariantPtr, p_argument_count: GDE.GDExtensionInt, p_return: GDE.GDExtensionVariantPtr, p_error: [*c]GDE.GDExtensionCallError) callconv(.C) void {
            _ = p_error;
            const method: *MethodType = @ptrCast(@alignCast(p_method_userdata));
            if (ArgCount == 0) {
                if (ReturnType == void or ReturnType == null) {
                    @call(.auto, method, .{});
                } else {
                    @as(*Variant, @ptrCast(p_return)).* = @call(.auto, method, .{});
                }
            } else {
                var variants: [ArgCount - 1]Variant = undefined;
                var args: std.meta.ArgsTuple(MethodType) = undefined;
                args[0] = @ptrCast(@alignCast(p_instance));
                inline for (0..ArgCount - 1) |i| {
                    if (i < p_argument_count) {
                        GD.variantNewCopy(@ptrCast(&variants[i]), @ptrCast(p_args[i]));
                    }

                    args[i + 1] = variants[i].as(ArgsTuple[i + 1].type);
                }
                if (ReturnType == void or ReturnType == null) {
                    @call(.auto, method, args);
                } else {
                    @as(*Variant, @ptrCast(p_return)).* = @call(.auto, method, args);
                }
            }
        }

        fn ptrToArg(comptime T: type, p_arg: GDE.GDExtensionConstTypePtr) T {
            switch (@typeInfo(T)) {
                .Pointer => |pointer| {
                    const ObjectType = pointer.child;
                    const ObjectTypeName = comptime getBaseName(@typeName(ObjectType));
                    const callbacks = @field(ObjectType, "callbacks_" ++ ObjectTypeName);
                    if (@hasDecl(ObjectType, "reference") and @hasDecl(ObjectType, "unreference")) { //RefCounted
                        const obj = GD.refGetObject(p_arg);
                        return @ptrCast(@alignCast(GD.objectGetInstanceBinding(obj, GD.p_library, @ptrCast(&callbacks))));
                    } else { //normal Object*
                        return @ptrCast(@alignCast(GD.objectGetInstanceBinding(p_arg, GD.p_library, @ptrCast(&callbacks))));
                    }
                },
                else => {
                    return @as(*T, @ptrCast(@constCast(@alignCast(p_arg)))).*;
                },
            }
        }

        pub fn bind_ptrcall(p_method_userdata: ?*anyopaque, p_instance: GDE.GDExtensionClassInstancePtr, p_args: [*c]const GDE.GDExtensionConstTypePtr, p_return: GDE.GDExtensionTypePtr) callconv(.C) void {
            const method: *MethodType = @ptrCast(@alignCast(p_method_userdata));
            if (ArgCount == 0) {
                if (ReturnType == void or ReturnType == null) {
                    @call(.auto, method, .{});
                } else {
                    @as(*ReturnType.?, @ptrCast(p_return)).* = @call(.auto, method, .{});
                }
            } else {
                var args: std.meta.ArgsTuple(MethodType) = undefined;
                args[0] = @ptrCast(@alignCast(p_instance));
                inline for (1..ArgCount) |i| {
                    args[i] = ptrToArg(ArgsTuple[i].type, p_args[i - 1]);
                }
                if (ReturnType == void or ReturnType == null) {
                    @call(.auto, method, args);
                } else {
                    @as(*ReturnType.?, @ptrCast(p_return)).* = @call(.auto, method, args);
                }
            }
        }
    };
}

var registered_methods: std.StringHashMap(bool) = undefined;
pub fn registerMethod(comptime T: type, comptime name: [:0]const u8) void {
    //prevent duplicate registration
    const fullname = std.mem.concat(GD.arena_allocator, u8, &[_][]const u8{ getBaseName(@typeName(T)), "::", name }) catch unreachable;
    if (registered_methods.contains(fullname)) return;
    registered_methods.put(fullname, true) catch unreachable;

    const p_method = @field(T, name);
    const MethodBinder = MethodBinderT(@TypeOf(p_method));

    MethodBinder.method_name = StringName.initFromLatin1Chars(name);
    MethodBinder.arg_metadata[0] = GDE.GDEXTENSION_METHOD_ARGUMENT_METADATA_NONE;
    MethodBinder.arg_properties[0] = GDE.GDExtensionPropertyInfo{
        .type = @intCast(Variant.getVariantType(MethodBinder.ReturnType.?)),
        .name = @ptrCast(@constCast(&StringName.init())),
        .class_name = @ptrCast(@constCast(&StringName.init())),
        .hint = GD.GlobalEnums.PROPERTY_HINT_NONE,
        .hint_string = @ptrCast(@constCast(&String.init())),
        .usage = GD.GlobalEnums.PROPERTY_USAGE_NONE,
    };

    inline for (1..MethodBinder.ArgCount) |i| {
        MethodBinder.arg_properties[i] = GDE.GDExtensionPropertyInfo{
            .type = @intCast(Variant.getVariantType(MethodBinder.ArgsTuple[i].type)),
            .name = @ptrCast(@constCast(&StringName.init())),
            .class_name = getClassName(MethodBinder.ArgsTuple[i].type),
            .hint = GD.GlobalEnums.PROPERTY_HINT_NONE,
            .hint_string = @ptrCast(@constCast(&String.init())),
            .usage = GD.GlobalEnums.PROPERTY_USAGE_NONE,
        };

        MethodBinder.arg_metadata[i + 1] = GDE.GDEXTENSION_METHOD_ARGUMENT_METADATA_NONE;
    }

    MethodBinder.method_info = GDE.GDExtensionClassMethodInfo{
        .name = @ptrCast(&MethodBinder.method_name),
        .method_userdata = @ptrCast(@constCast(&p_method)),
        .call_func = MethodBinder.bind_call,
        .ptrcall_func = MethodBinder.bind_ptrcall,
        .method_flags = GDE.GDEXTENSION_METHOD_FLAG_NORMAL,
        .has_return_value = if (MethodBinder.ReturnType != void) 1 else 0,
        .return_value_info = @ptrCast(&MethodBinder.arg_properties[0]),
        .return_value_metadata = MethodBinder.arg_metadata[0],
        .argument_count = MethodBinder.ArgCount - 1,
        .arguments_info = @ptrCast(&MethodBinder.arg_properties[1]),
        .arguments_metadata = @ptrCast(&MethodBinder.arg_metadata[1]),
        .default_argument_count = 0,
        .default_arguments = null,
    };

    GD.classdbRegisterExtensionClassMethod(GD.p_library, getClassName(T), &MethodBinder.method_info);
}

var registered_signals: std.StringHashMap(bool) = undefined;
pub fn registerSignal(comptime T: type, comptime signal_name: [:0]const u8, arguments: []const PropertyInfo) void {
    //prevent duplicate registration
    const fullname = std.mem.concat(GD.arena_allocator, u8, &[_][]const u8{ getBaseName(@typeName(T)), "::", signal_name }) catch unreachable;
    if (registered_signals.contains(fullname)) return;
    registered_signals.put(fullname, true) catch unreachable;

    var propertyies: [32]GDE.GDExtensionPropertyInfo = undefined;
    if (arguments.len > 32) {
        std.log.err("why you need so many arguments for a single signal? whatever, you can increase the upper limit as you want", .{});
    }

    for (arguments, 0..) |*a, i| {
        propertyies[i].type = a.type;
        propertyies[i].hint = a.hint;
        propertyies[i].usage = a.usage;
        propertyies[i].name = @ptrCast(@constCast(&a.name));
        propertyies[i].class_name = @ptrCast(@constCast(&a.class_name));
        propertyies[i].hint_string = @ptrCast(@constCast(&a.hint_string));
    }

    if (arguments.len > 0) {
        GD.classdbRegisterExtensionClassSignal(GD.p_library, getClassName(T), &StringName.initFromLatin1Chars(signal_name), &propertyies[0], @intCast(arguments.len));
    } else {
        GD.classdbRegisterExtensionClassSignal(GD.p_library, getClassName(T), &StringName.initFromLatin1Chars(signal_name), null, 0);
    }
}

pub fn connect(godot_object: anytype, signal_name: [:0]const u8, instance: anytype, comptime method_name: [:0]const u8) void {
    if (@typeInfo(@TypeOf(instance)) != .Pointer) {
        @compileError("pointer type expected for parameter 'instance'");
    }
    registerMethod(std.meta.Child(@TypeOf(instance)), method_name);
    const callable = GD.Callable.initFromObjectStringName(instance, method_name);
    _ = godot_object.connect(signal_name, callable, 0);
}

pub fn castTo(object: anytype, comptime TargetType: type) ?*TargetType {
    const classTag = GD.classdbGetClassTag(@ptrCast(getClassName(TargetType)));
    const casted = GD.objectCastTo(object.godot_object, classTag);
    if (casted) |c| {
        if (getObjectInstanceBinding(c)) |r| {
            return @ptrCast(@alignCast(r));
        }
    }
    return null;
}

pub fn init(getProcAddress: std.meta.Child(GDE.GDExtensionInterfaceGetProcAddress), library: GDE.GDExtensionClassLibraryPtr, allocator_: std.mem.Allocator) !void {
    registered_classes = std.StringHashMap(bool).init(allocator_);
    registered_methods = std.StringHashMap(bool).init(allocator_);
    registered_signals = std.StringHashMap(bool).init(allocator_);
    return GD.initCore(getProcAddress, library, allocator_);
}

pub fn deinit() void {
    GD.deinitCore();
    registered_signals.deinit();
    registered_methods.deinit();
    registered_classes.deinit();
}

pub const PropertyInfo = struct {
    type: GDE.GDExtensionVariantType = GDE.GDEXTENSION_VARIANT_TYPE_NIL,
    name: StringName,
    class_name: StringName,
    hint: u32 = GD.GlobalEnums.PROPERTY_HINT_NONE,
    hint_string: String,
    usage: u32 = GD.GlobalEnums.PROPERTY_USAGE_DEFAULT,
    const Self = @This();

    pub fn init(@"type": GDE.GDExtensionVariantType, name: StringName) Self {
        return .{
            .type = @"type",
            .name = name,
            .hint_string = String.initFromUtf8Chars("test property"),
            .class_name = StringName.initFromLatin1Chars(""),
            .hint = GD.GlobalEnums.PROPERTY_HINT_NONE,
            .usage = GD.GlobalEnums.PROPERTY_USAGE_DEFAULT,
        };
    }

    pub fn initFull(@"type": GDE.GDExtensionVariantType, name: StringName, class_name: StringName, hint: u32, hint_string: String, usage: u32) Self {
        return .{
            .type = @"type",
            .name = name,
            .class_name = class_name,
            .hint_string = hint_string,
            .hint = hint,
            .usage = usage,
        };
    }
};
