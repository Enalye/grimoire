/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.compiler.constraint;

import grimoire.compiler.type;

private {
    GrConstraint.Data[string] _constraints;
}

/// Template function constraint
final class GrConstraint {
    alias Predicate = bool function(GrType, GrType[]);

    struct Data {
        Predicate predicate;
        uint arity;
    }

    package {
        Data _data;
        GrType _type;
        GrType[] _parameters;
    }

    /// Ctor
    this(Predicate predicate, uint arity, GrType type, GrType[] parameters) {
        _data.predicate = predicate;
        _data.arity = arity;
        _type = type;
        _parameters = parameters;
    }

    /// Checks if the types validate the constraint
    bool evaluate(GrAnyData data) {
        GrType type = _type.isAny ? data.get(_type.mangledType) : _type;
        GrType[] parameters;
        foreach (GrType parameter; _parameters) {
            parameters ~= parameter.isAny ? data.get(parameter.mangledType) : parameter;
        }
        return _data.predicate(type, parameters);
    }
}

/// Setup a constraint object from a registered constraint
GrConstraint grConstraint(string name, GrType type, GrType[] parameters = []) {
    GrConstraint.Data data = grGetConstraint(name);
    if (!data.predicate)
        throw new Exception("unregistered template constraint");
    return new GrConstraint(data.predicate, data.arity, type, parameters);
}

/// Register a new constraint
void grAddConstraint(string name, GrConstraint.Predicate predicate, uint arity) {
    GrConstraint.Data data;
    data.predicate = predicate;
    data.arity = arity;
    _constraints[name] = data;
}

/// Fetch a registered constraint
GrConstraint.Data grGetConstraint(string name) {
    GrConstraint.Data* func = name in _constraints;
    return func ? *func : GrConstraint.Data();
}

string[] grGetAllConstraintsName() {
    return _constraints.keys;
}
