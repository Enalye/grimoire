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
}

private bool _register(GrType type, GrType[] types) {
    if(types.length != 1)
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

private bool _enum(GrType type, GrType[] types) {
    return type.base == GrType.Base.enum_;
}

private bool _channel(GrType type, GrType[] types) {
    return type.base == GrType.Base.channel;
}

private bool _function(GrType type, GrType[] types) {
    return type.base == GrType.Base.function_;
}

private bool _task(GrType type, GrType[] types) {
    return type.base == GrType.Base.task;
}

private bool _callable(GrType type, GrType[] types) {
    return type.base == GrType.Base.function_ || type.base == GrType.Base.task;
}

private bool _class(GrType type, GrType[] types) {
    return type.base == GrType.Base.class_;
}

private bool _foreign(GrType type, GrType[] types) {
    return type.base == GrType.Base.foreign;
}