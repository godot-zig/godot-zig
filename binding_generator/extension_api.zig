const string = []const u8;
const int = i64;

header: struct {
    version_major: int,
    version_minor: int,
    version_patch: int,
    version_status: string,
    version_build: string,
    version_full_name: string,
},
builtin_class_sizes: []struct {
    build_configuration: string,
    sizes: []struct {
        name: string,
        size: int,
    },
},
builtin_class_member_offsets: []struct {
    build_configuration: string,
    classes: []struct {
        name: string,
        members: []struct {
            member: string,
            offset: int,
            meta: string,
        },
    },
},
global_enums: []struct {
    name: string,
    is_bitfield: bool,
    values: []struct {
        name: string,
        value: int,
    },
},
global_constants: []struct { name: string, value: string },
utility_functions: []struct {
    name: string,
    return_type: string = "",
    category: string,
    is_vararg: bool,
    hash: u64,
    arguments: ?[]struct {
        name: string,
        type: string,
    } = null,
},
builtin_classes: []struct {
    name: string,
    indexing_return_type: string = "",
    is_keyed: bool,
    members: ?[]struct {
        name: string,
        type: string,
    } = null,
    constants: ?[]struct {
        name: string,
        type: string,
        value: string,
    } = null,
    enums: ?[]struct {
        name: string,
        values: []struct {
            name: string,
            value: int,
        },
    } = null,
    operators: []struct {
        name: string,
        right_type: string = "",
        return_type: string,
    },
    methods: ?[]struct {
        name: string,
        return_type: string = "void",
        is_vararg: bool,
        is_const: bool,
        is_static: bool,
        hash: u64,
        arguments: ?[]struct {
            name: string,
            type: string,
            default_value: string = "",
        } = null,
    } = null,
    constructors: []struct {
        index: int,
        arguments: ?[]struct {
            name: string,
            type: string,
        } = null,
    },
    has_destructor: bool,
},
classes: []struct {
    name: string,
    is_refcounted: bool,
    is_instantiable: bool,
    inherits: string = "",
    api_type: string,
    constants: ?[]struct {
        name: string,
        value: int,
    } = null,
    enums: ?[]struct {
        name: string,
        is_bitfield: bool,
        values: []struct {
            name: string,
            value: int,
        },
    } = null,
    methods: ?[]struct {
        name: string,
        is_const: bool,
        is_static: bool,
        is_vararg: bool,
        is_virtual: bool,
        hash: u64 = 0,
        hash_compatibility: ?[]u64 = null,
        return_value: ?struct {
            type: string,
            meta: string = "",
            default_value: string = "",
        } = null,
        arguments: ?[]struct {
            name: string,
            type: string,
            meta: string = "",
            default_value: string = "",
        } = null,
    } = null,
    signals: ?[]struct {
        name: string,
        arguments: ?[]struct {
            name: string,
            type: string,
        } = null,
    } = null,
    properties: ?[]struct {
        type: string,
        name: string,
        setter: string = "",
        getter: string,
        index: int = -1,
    } = null,
},
singletons: []struct {
    name: string,
    type: string,
},
native_structures: []struct {
    name: string,
    format: string,
},
