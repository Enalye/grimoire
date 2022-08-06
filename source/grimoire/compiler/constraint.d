/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.compiler.constraint;

import grimoire.compiler.type, grimoire.compiler.data;

private {
    GrConstraint.Data[string] _constraints;
}

/// Template function constraint
final class GrConstraint {
    alias Predicate = bool function(GrData, GrType, const GrType[]);

    struct Data {
        Predicate predicate;
        uint arity;
    }

    package {
        Data _data;
        GrType _type;
        const GrType[] _parameters;
    }

    /// Ctor
    this(Predicate predicate, uint arity, GrType type, const GrType[] parameters) {
        _data.predicate = predicate;
        _data.arity = arity;
        _type = type;
        _parameters = parameters;
    }

    this(const GrConstraint constraint) {
        _data.predicate = constraint._data.predicate;
        _data.arity = constraint._data.arity;
        _type = constraint._type;
        _parameters = constraint._parameters.dup;
    }

    /// Checks if the types validate the constraint
    bool evaluate(GrData data, const GrAnyData anyData) {
        GrType type = _type.isAny ? anyData.get(_type.mangledType) : _type;
        GrType[] parameters;
        foreach (GrType parameter; _parameters) {
            parameters ~= parameter.isAny ? anyData.get(parameter.mangledType) : parameter;
        }
        return _data.predicate(data, type, parameters);
    }
}

/// Setup a constraint object from a registered constraint
GrConstraint grConstraint(const string name, GrType type, const GrType[] parameters = []) {
    GrConstraint.Data data = grGetConstraint(name);
    if (!data.predicate)
        throw new Exception("unregistered template constraint");
    return new GrConstraint(data.predicate, data.arity, type, parameters);
}

/// Register a new constraint
void grAddConstraint(const string name, GrConstraint.Predicate predicate, uint arity) {
    GrConstraint.Data data;
    data.predicate = predicate;
    data.arity = arity;
    _constraints[name] = data;
}

/// Fetch a registered constraint
GrConstraint.Data grGetConstraint(const string name) {
    GrConstraint.Data* func = name in _constraints;
    return func ? *func : GrConstraint.Data();
}

const(string[]) grGetAllConstraintsName() {
    return _constraints.keys;
}
