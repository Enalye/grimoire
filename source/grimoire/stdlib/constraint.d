/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.stdlib.constraint;

import grimoire.compiler;
import grimoire.stdlib.util;

void grLoadStdLibConstraint() {
    grAddConstraint("Pure", &_pure, 0);
    grAddConstraint("Register", &_register, 1);
    grAddConstraint("Enum", &_enum, 0);
    grAddConstraint("Channel", &_channel, 0);
    grAddConstraint("Function", &_function, 0);
    grAddConstraint("Task", &_task, 0);
    grAddConstraint("Callable", &_callable, 0);
    grAddConstraint("Class", &_class, 0);
    grAddConstraint("Native", &_native, 0);
    grAddConstraint("Numeric", &_numeric, 0);
    grAddConstraint("NotNullable", &_notnullable, 0);
    grAddConstraint("Nullable", &_nullable, 0);
    grAddConstraint("Is", &_is, 1);
    grAddConstraint("Not", &_not, 1);
    grAddConstraint("Base", &_base, 1);
    grAddConstraint("Extends", &_extends, 1);
}

private bool _pure(GrData, GrType type, const GrType[]) {
    return type.isPure;
}

private bool _register(GrData, GrType type, const GrType[] types) {
    if (types.length != 1)
        return false;
    final switch (types[0].base) with (GrType.Base) {
    case int_:
    case bool_:
    case enum_:
    case func:
    case task:
    case event:
        return type == GrType.Base.int_ || type == GrType.Base.bool_ ||
            type == GrType.Base.func || type == GrType.Base.task ||
            type == GrType.Base.event || type == GrType.Base.enum_;
    case uint_:
        return type == GrType.Base.uint_;
    case float_:
        return type == GrType.Base.float_;
    case string_:
        return type == GrType.Base.string_;
    case optional:
    case list:
    case channel:
    case class_:
    case native:
    case reference:
    case null_:
        return type == GrType.Base.optional || type == GrType.Base.class_ ||
            type == GrType.Base.list || type == GrType.Base.native ||
            type == GrType.Base.channel || type == GrType.Base.reference || type == GrType
            .Base.null_;
    case void_:
    case internalTuple:
        return false;
    }
}

private bool _enum(GrData, GrType type, const GrType[]) {
    return type.base == GrType.Base.enum_;
}

private bool _channel(GrData, GrType type, const GrType[]) {
    return type.base == GrType.Base.channel;
}

private bool _function(GrData, GrType type, const GrType[]) {
    return type.base == GrType.Base.func;
}

private bool _task(GrData, GrType type, const GrType[]) {
    return type.base == GrType.Base.task;
}

private bool _callable(GrData, GrType type, const GrType[]) {
    return type.base == GrType.Base.func || type.base == GrType.Base.task;
}

private bool _class(GrData, GrType type, const GrType[]) {
    return type.base == GrType.Base.class_;
}

private bool _native(GrData, GrType type, const GrType[]) {
    return type.base == GrType.Base.native;
}

private bool _numeric(GrData, GrType type, const GrType[]) {
    return type.base == GrType.Base.int_ || type.base == GrType.Base.float_;
}

private bool _notnullable(GrData, GrType type, const GrType[]) {
    final switch (type.base) with (GrType.Base) {
    case bool_:
    case int_:
    case uint_:
    case float_:
    case enum_:
    case string_:
    case list:
    case channel:
    case func:
    case task:
    case event:
    case class_:
    case native:
    case reference:
        return true;
    case optional:
    case null_:
    case void_:
    case internalTuple:
        return false;
    }
}

private bool _nullable(GrData, GrType type, const GrType[]) {
    final switch (type.base) with (GrType.Base) {
    case bool_:
    case int_:
    case uint_:
    case float_:
    case enum_:
    case string_:
    case list:
    case channel:
    case func:
    case task:
    case event:
    case class_:
    case native:
    case reference:
        return false;
    case optional:
    case null_:
    case void_:
    case internalTuple:
        return true;
    }
}

private bool _is(GrData, GrType type, const GrType[] types) {
    return type == types[0];
}

private bool _not(GrData, GrType type, const GrType[] types) {
    return type != types[0];
}

private bool _base(GrData data, GrType type, const GrType[] types) {
    if (type.base == GrType.Base.native && types[0].base == GrType.Base.native) {
        GrType baseType = types[0];
        for (;;) {
            if (type == baseType)
                return true;
            const GrNativeDefinition nativeType = data.getNative(baseType.mangledType);
            if (!nativeType.parent.length)
                return false;
            baseType.mangledType = nativeType.parent;
        }
    }
    else if (type.base == GrType.Base.class_ && types[0].base == GrType.Base.class_) {
        GrType baseType = types[0];
        for (;;) {
            if (type == baseType)
                return true;
            const GrClassDefinition classType = data.getClass(baseType.mangledType, 0, true);
            if (!classType.parent.length)
                return false;
            baseType.mangledType = classType.parent;
        }
    }
    return false;
}

private bool _extends(GrData data, GrType type, const GrType[] types) {
    if (type.base == GrType.Base.native && types[0].base == GrType.Base.native) {
        for (;;) {
            if (type == types[0])
                return true;
            const GrNativeDefinition nativeType = data.getNative(type.mangledType);
            if (!nativeType.parent.length)
                return false;
            type.mangledType = nativeType.parent;
        }
    }
    else if (type.base == GrType.Base.class_ && types[0].base == GrType.Base.class_) {
        for (;;) {
            if (type == types[0])
                return true;
            const GrClassDefinition classType = data.getClass(type.mangledType, 0, true);
            if (!classType.parent.length)
                return false;
            type.mangledType = classType.parent;
        }
    }
    return false;
}
