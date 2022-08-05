/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.constraint;

import grimoire.compiler;
import grimoire.stdlib.util;

package(grimoire.stdlib) void grLoadStdLibConstraint() {
    grAddConstraint("Register", &_register, 1);
    grAddConstraint("Enum", &_enum, 0);
    grAddConstraint("Channel", &_channel, 0);
    grAddConstraint("Function", &_function, 0);
    grAddConstraint("Task", &_task, 0);
    grAddConstraint("Callable", &_callable, 0);
    grAddConstraint("Class", &_class, 0);
    grAddConstraint("Foreign", &_foreign, 0);
    grAddConstraint("Numeric", &_numeric, 0);
    grAddConstraint("NotNullable", &_notnullable, 0);
    grAddConstraint("Nullable", &_nullable, 0);
    grAddConstraint("Is", &_is, 1);
    grAddConstraint("Not", &_not, 1);
    grAddConstraint("Base", &_base, 1);
    grAddConstraint("Extends", &_extends, 1);
}

private bool _register(GrData, GrType type, GrType[] types) {
    if (types.length != 1)
        return false;
    final switch (types[0].base) with (GrType.Base) {
    case int_:
    case bool_:
    case enum_:
    case function_:
    case task:
        return type == GrType.Base.int_ || type == GrType.Base.bool_
            || type == GrType.Base.function_ || type == GrType.Base.task || type == GrType
            .Base.enum_;
    case real_:
        return type == GrType.Base.real_;
    case string_:
        return type == GrType.Base.string_;
    case array:
    case channel:
    case class_:
    case foreign:
    case reference:
    case null_:
        return type == GrType.Base.class_ || type == GrType.Base.array || type == GrType.Base.foreign
            || type == GrType.Base.channel || type == GrType.Base.reference || type == GrType
            .Base.null_;
    case void_:
    case internalTuple:
        return false;
    }
}

private bool _enum(GrData, GrType type, GrType[]) {
    return type.base == GrType.Base.enum_;
}

private bool _channel(GrData, GrType type, GrType[]) {
    return type.base == GrType.Base.channel;
}

private bool _function(GrData, GrType type, GrType[]) {
    return type.base == GrType.Base.function_;
}

private bool _task(GrData, GrType type, GrType[]) {
    return type.base == GrType.Base.task;
}

private bool _callable(GrData, GrType type, GrType[]) {
    return type.base == GrType.Base.function_ || type.base == GrType.Base.task;
}

private bool _class(GrData, GrType type, GrType[]) {
    return type.base == GrType.Base.class_;
}

private bool _foreign(GrData, GrType type, GrType[]) {
    return type.base == GrType.Base.foreign;
}

private bool _numeric(GrData, GrType type, GrType[]) {
    return type.base == GrType.Base.int_ || type.base == GrType.Base.real_;
}

private bool _notnullable(GrData, GrType type, GrType[]) {
    final switch (type.base) with (GrType.Base) {
    case bool_:
    case int_:
    case real_:
    case enum_:
    case string_:
    case array:
    case channel:
    case function_:
    case task:
        return true;
    case class_:
    case foreign:
    case reference:
    case null_:
    case void_:
    case internalTuple:
        return false;
    }
}

private bool _nullable(GrData, GrType type, GrType[]) {
    final switch (type.base) with (GrType.Base) {
    case bool_:
    case int_:
    case real_:
    case enum_:
    case string_:
    case array:
    case channel:
    case function_:
    case task:
        return false;
    case class_:
    case foreign:
    case reference:
    case null_:
    case void_:
    case internalTuple:
        return true;
    }
}

private bool _is(GrData, GrType type, GrType[] types) {
    return type == types[0];
}

private bool _not(GrData, GrType type, GrType[] types) {
    return type != types[0];
}

private bool _base(GrData data, GrType type, GrType[] types) {
    if (type.base == GrType.Base.foreign && types[0].base == GrType.Base.foreign) {
        for (;;) {
            if (type == types[0])
                return true;
            const GrForeignDefinition foreignType = data.getForeign(types[0].mangledType);
            if (!foreignType.parent.length)
                return false;
            types[0].mangledType = foreignType.parent;
        }
    }
    else if (type.base == GrType.Base.class_ && types[0].base == GrType.Base.class_) {
        for (;;) {
            if (type == types[0])
                return true;
            const GrClassDefinition classType = data.getClass(types[0].mangledType, 0, true);
            if (!classType.parent.length)
                return false;
            types[0].mangledType = classType.parent;
        }
    }
    return false;
}

private bool _extends(GrData data, GrType type, GrType[] types) {
    if (type.base == GrType.Base.foreign && types[0].base == GrType.Base.foreign) {
        for (;;) {
            if (type == types[0])
                return true;
            const GrForeignDefinition foreignType = data.getForeign(type.mangledType);
            if (!foreignType.parent.length)
                return false;
            type.mangledType = foreignType.parent;
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