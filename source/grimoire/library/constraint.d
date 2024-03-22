/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.library.constraint;

import grimoire;

void grLoadStdLibConstraint(GrModule library) {
    library.setModule("constraint");

    library.setModuleInfo(GrLocale.fr_FR, "Constraintes de base.");
    library.setModuleInfo(GrLocale.en_US, "Basic constraints.");

    library.setDescription(GrLocale.fr_FR, "Le type est pur");
    library.setDescription(GrLocale.en_US, "The type is pure");
    library.addConstraint(&_pure, "Pure");

    library.setDescription(GrLocale.fr_FR,
        "Les deux types utilisent le même registre de la machine virtuelle");
    library.setDescription(GrLocale.en_US, "Both types use the same virtual machine register");
    library.addConstraint(&_register, "Register", 1);

    library.setDescription(GrLocale.fr_FR, "Le type est une énumération");
    library.setDescription(GrLocale.en_US, "The type is an enumeration");
    library.addConstraint(&_enum, "Enum");

    library.setDescription(GrLocale.fr_FR, "Le type est un canal");
    library.setDescription(GrLocale.en_US, "The type is a channel");
    library.addConstraint(&_channel, "Channel");

    library.setDescription(GrLocale.fr_FR, "Le type est une fonction");
    library.setDescription(GrLocale.en_US, "The type is a function");
    library.addConstraint(&_function, "Function");

    library.setDescription(GrLocale.fr_FR, "Le type est une tâche");
    library.setDescription(GrLocale.en_US, "The type is a task");
    library.addConstraint(&_task, "Task");

    library.setDescription(GrLocale.fr_FR, "Le type est appelable");
    library.setDescription(GrLocale.en_US, "The type is callable");
    library.addConstraint(&_callable, "Callable");

    library.setDescription(GrLocale.fr_FR, "Le type est une classe");
    library.setDescription(GrLocale.en_US, "The type is a class");
    library.addConstraint(&_class, "Class");

    library.setDescription(GrLocale.fr_FR, "Le type est un natif");
    library.setDescription(GrLocale.en_US, "The type is a native");
    library.addConstraint(&_native, "Native");

    library.setDescription(GrLocale.fr_FR, "Le type est un nombre");
    library.setDescription(GrLocale.en_US, "The type is a number");
    library.addConstraint(&_numeric, "Numeric");

    library.setDescription(GrLocale.fr_FR, "Le type est un nombre intégral");
    library.setDescription(GrLocale.en_US, "The type is an integral number");
    library.addConstraint(&_integral, "Integral");

    library.setDescription(GrLocale.fr_FR, "Le type est un nombre flottant");
    library.setDescription(GrLocale.en_US, "The type is a floating point number");
    library.addConstraint(&_floating, "Floating");

    library.setDescription(GrLocale.fr_FR, "Le type doit avoir une valeur");
    library.setDescription(GrLocale.en_US, "The type must have a value");
    library.addConstraint(&_notnullable, "NotNullable");

    library.setDescription(GrLocale.fr_FR, "Le type peut ne rien valoir");
    library.setDescription(GrLocale.en_US, "The type can have no value");
    library.addConstraint(&_nullable, "Nullable");

    library.setDescription(GrLocale.fr_FR, "Les deux types sont égaux");
    library.setDescription(GrLocale.en_US, "Both types are the same");
    library.addConstraint(&_is, "Is", 1);

    library.setDescription(GrLocale.fr_FR, "Les deux types sont différents");
    library.setDescription(GrLocale.en_US, "Both types are the different");
    library.addConstraint(&_not, "Not", 1);

    library.setDescription(GrLocale.fr_FR, "Le premier type est un parent du second");
    library.setDescription(GrLocale.en_US, "The first type is a parent of the second one");
    library.addConstraint(&_base, "Base", 1);

    library.setDescription(GrLocale.fr_FR, "Le premier type est un enfant du second");
    library.setDescription(GrLocale.en_US, "The first type is a child of the second one");
    library.addConstraint(&_extends, "Extends", 1);
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
        return type == GrType.Base.int_ || type == GrType.Base.bool_ ||
            type == GrType.Base.func || type == GrType.Base.task ||
            type == GrType.Base.event || type == GrType.Base.enum_;
    case uint_:
    case char_:
        return type == GrType.Base.uint_ || type == GrType.Base.char_;
    case byte_:
        return type == GrType.Base.byte_;
    case float_:
        return type == GrType.Base.float_;
    case double_:
        return type == GrType.Base.double_;
    case string_:
        return type == GrType.Base.string_;
    case optional:
    case list:
    case channel:
    case class_:
    case native:
    case func:
    case task:
    case event:
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
    return type.isNumeric;
}

private bool _integral(GrData, GrType type, const GrType[]) {
    return type.isIntegral;
}

private bool _floating(GrData, GrType type, const GrType[]) {
    return type.isFloating;
}

private bool _notnullable(GrData, GrType type, const GrType[]) {
    final switch (type.base) with (GrType.Base) {
    case bool_:
    case int_:
    case uint_:
    case char_:
    case byte_:
    case float_:
    case double_:
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
    case char_:
    case byte_:
    case float_:
    case double_:
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
