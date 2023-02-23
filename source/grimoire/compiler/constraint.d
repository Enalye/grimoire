/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.compiler.constraint;

import grimoire.compiler.type, grimoire.compiler.data;

/// Restriction de modèle de fonction
struct GrConstraint {
    alias Predicate = bool function(GrData, GrType, const GrType[]);

    package final class Data {
        Predicate predicate;
        uint arity;

        this(Predicate predicate_, uint arity_ = 0) {
            predicate = predicate_;
            arity = arity_;
        }

        this(const Data data) {
            predicate = data.predicate;
            arity = data.arity;
        }
    }

    private {
        enum InternalType {
            primitive,
            function_
        }

        InternalType _internalType;

        union {
            string _name;
            Data _data;
        }

        GrType _type;
        const GrType[] _parameters;
    }

    this(string name, GrType type, const GrType[] parameters) {
        _internalType = InternalType.primitive;
        _name = name;
        _type = type;
        _parameters = parameters;
    }

    this(Predicate predicate, uint arity, GrType type, const GrType[] parameters) {
        _internalType = InternalType.function_;
        _data = new Data(predicate, arity);
        _type = type;
        _parameters = parameters;
    }

    this(const ref GrConstraint constraint) {
        _type = constraint._type;
        _parameters = constraint._parameters.dup;

        _internalType = constraint._internalType;
        final switch (_internalType) with (InternalType) {
        case primitive:
            _name = constraint._name;
            break;
        case function_:
            _data = new Data(constraint._data);
            break;
        }
    }

    /// Vérifie si les types sont validés par la contrainte
    bool evaluate(GrData data, const GrAnyData anyData) {
        Predicate predicate;

        final switch (_internalType) with (InternalType) {
        case primitive:
            Data constraintData = data.getConstraintData(_name);
            predicate = constraintData.predicate;
            break;
        case function_:
            predicate = _data.predicate;
            break;
        }

        if (!predicate)
            return false;

        GrType type = _type.isAny ? anyData.get(_type.mangledType) : _type;
        GrType[] parameters;
        foreach (GrType parameter; _parameters) {
            parameters ~= parameter.isAny ? anyData.get(parameter.mangledType) : parameter;
        }
        return predicate(data, type, parameters);
    }
}

/// Référence une contrainte
GrConstraint grConstraint(const string name, GrType type, const GrType[] parameters = [
    ]) {
    return GrConstraint(name, type, parameters);
}
