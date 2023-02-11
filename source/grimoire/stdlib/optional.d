/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.stdlib.optional;

import grimoire.compiler, grimoire.runtime, grimoire.assembly;
import grimoire.stdlib.util;

void grLoadStdLibOptional(GrLibDefinition library) {
    library.setModule(["std", "optional"]);

    library.setModuleInfo(GrLocale.fr_FR, "Fonctions pour la manipulation d’optionnels.");
    library.setModuleInfo(GrLocale.en_US, "Optionals handling functions.");

    library.setModuleDescription(GrLocale.fr_FR,
        "Un optionnel est un type pouvant contenir son propre type ou être nul.
Son type nul correspondant vaut `null<T>` où `T` est le type concerné.");
    library.setModuleDescription(GrLocale.en_US,
        "An optiona is a type that can contains its own type or be null.
Its null type is equal to `null<T>` where `T` is the referenced type.");

    library.setDescription(GrLocale.fr_FR, "Retourne une version optionnelle du type.");
    library.setDescription(GrLocale.en_US, "Returns an optional version of the type.");
    library.setParameters(GrLocale.fr_FR, ["x"]);
    library.setParameters(GrLocale.en_US, ["x"]);
    library.addFunction(&_some, "some", [grAny("T")],
        [grOptional(grAny("T"))], [grConstraint("NotNullable", grAny("T"))]);

    library.setDescription(GrLocale.fr_FR, "Vérifie si un optionnel est nul.
S’il est nul, l’exception `erreur` est lancé.
Sinon, la version non-optionnel de `x` est renvoyé.");
    library.setDescription(GrLocale.en_US, "Checks if an optionnal is null.
If it is, the exception `error` is thrown.
Otherwise, the non-optional version of `x` is returned.");
    library.setParameters(GrLocale.fr_FR, ["x", "erreur"]);
    library.setParameters(GrLocale.en_US, ["x", "error"]);
    library.addFunction(&_expect, "expect", [
            grOptional(grAny("T")), grPure(grString)
        ], [grAny("T")]);

    library.setDescription(GrLocale.fr_FR, "Vérifie si un optionnel est nul.
S’il est nul, l’exception `\"UnwrapError\"` est lancé.
Sinon, la version non-optionnel de `x` est renvoyé.");
    library.setDescription(GrLocale.en_US, "Checks if an optionnal is null.
If it is, the exception `\"UnwrapError\"` is thrown.
Otherwise, the non-optional version of `x` is returned.");
    library.setParameters(GrLocale.fr_FR, ["x"]);
    library.setParameters(GrLocale.en_US, ["x"]);
    library.addFunction(&_unwrap, "unwrap", [grOptional(grAny("T"))], [
            grAny("T")
        ]);

    library.setDescription(GrLocale.fr_FR, "Vérifie si un optionnel est nul.
S’il est nul, la valeur par `défaut` est retourné.
Sinon, la version non-optionnel de `x` est renvoyé.");
    library.setDescription(GrLocale.en_US, "Checks if an optionnal is null.
If it is, the `default` value is returned.
Otherwise, the non-optional version of `x` is returned.");
    library.setParameters(GrLocale.fr_FR, ["x", "défaut"]);
    library.setParameters(GrLocale.en_US, ["x", "default"]);
    library.addFunction(&_unwrapOr, "unwrapOr", [
            grOptional(grAny("T")), grAny("T")
        ], [grAny("T")]);

    library.addOperator(&_opUnary!("~", "Int"),
        GrLibDefinition.Operator.bitwiseNot, [grOptional(grInt)], grOptional(grInt));

    static foreach (op; ["&", "|", "^", "<<", ">>"]) {
        library.addOperator(&_opBinary!(op, "Int", "Int", "Int"), op,
            [grOptional(grInt), grOptional(grInt)], grOptional(grInt));
    }

    static foreach (op; ["+", "-"]) {
        library.addOperator(&_opUnary!(op, "Int"), op, [grOptional(grInt)], grOptional(grInt));
        library.addOperator(&_opUnary!(op, "Float"), op, [grOptional(grFloat)], grOptional(grFloat));
    }

    static foreach (op; ["+", "-", "*", "/", "%"]) {
        library.addOperator(&_opBinary!(op, "Int", "Int", "Int"), op,
            [grOptional(grInt), grOptional(grInt)], grOptional(grInt));

        library.addOperator(&_opBinary!(op, "Float", "Float", "Float"), op,
            [grOptional(grFloat), grOptional(grFloat)], grOptional(grFloat));

        library.addOperator(&_opBinary!(op, "Float", "Int", "Float"), op,
            [grOptional(grFloat), grOptional(grInt)], grOptional(grFloat));

        library.addOperator(&_opBinary!(op, "Int", "Float", "Float"), op,
            [grOptional(grInt), grOptional(grFloat)], grOptional(grFloat));
    }

    library.addOperator(&_opUnary!("!", "Bool"),
        GrLibDefinition.Operator.not, [grOptional(grBool)], grOptional(grBool));

    static foreach (op; ["&&", "||"]) {
        library.addOperator(&_opBinary!(op, "Bool", "Bool", "Bool"), op,
            [grOptional(grBool), grOptional(grBool)], grOptional(grBool));
    }

    static foreach (op; ["==", "!="]) {
        library.addOperator(&_opEquality!(op, "Bool", "Bool"), op,
            [grOptional(grBool), grOptional(grBool)], grBool);

        library.addOperator(&_opEquality!(op, "Int", "Int"), op,
            [grOptional(grInt), grOptional(grInt)], grBool);

        library.addOperator(&_opEquality!(op, "Float", "Float"), op,
            [grOptional(grFloat), grOptional(grFloat)], grBool);

        library.addOperator(&_opEquality!(op, "Int", "Float"), op,
            [grOptional(grInt), grOptional(grFloat)], grBool);

        library.addOperator(&_opEquality!(op, "Float", "Int"), op,
            [grOptional(grFloat), grOptional(grInt)], grBool);
    }

    static foreach (op; [">", "<", ">=", "<="]) {
        library.addOperator(&_opComparison!(op, "Int", "Int"), op,
            [grOptional(grInt), grOptional(grInt)], grBool);

        library.addOperator(&_opComparison!(op, "Float", "Float"), op,
            [grOptional(grFloat), grOptional(grFloat)], grBool);

        library.addOperator(&_opComparison!(op, "Int", "Float"), op,
            [grOptional(grInt), grOptional(grFloat)], grBool);

        library.addOperator(&_opComparison!(op, "Float", "Int"), op,
            [grOptional(grFloat), grOptional(grInt)], grBool);
    }
}

private void _some(GrCall call) {
    call.setValue(call.getValue(0));
}

private void _unwrap(GrCall call) {
    if (call.isNull(0))
        call.raise("UnwrapError");
    else
        call.setValue(call.getValue(0));
}

private void _unwrapOr(GrCall call) {
    call.setValue(call.isNull(0) ? call.getValue(1) : call.getValue(0));
}

private void _expect(GrCall call) {
    if (call.isNull(0))
        call.raise(call.getString(1));
    else
        call.setValue(call.getValue(0));
}

private void _opUnary(string op, string t)(GrCall call) {
    if (call.isNull(0)) {
        call.setNull();
        return;
    }
    mixin("call.set" ~ t ~ "(" ~ op ~ " call.get" ~ t ~ "(0));");
}

private void _opBinary(string op, string t1, string t2, string ts)(GrCall call) {
    if (call.isNull(0) || call.isNull(1)) {
        call.setNull();
        return;
    }
    static if (op == "/" || op == "%") {
        mixin("const Gr" ~ t2 ~ " divider = call.get" ~ t2 ~ "(1);");
        if (divider == 0) {
            call.raise("NullDivisionError");
            return;
        }
    }
    mixin("call.set" ~ ts ~ "(call.get" ~ t1 ~ "(0) " ~ op ~ " call.get" ~ t2 ~ "(1));");
}

private void _opEquality(string op, string t1, string t2)(GrCall call) {
    if (call.isNull(0) && call.isNull(1)) {
        static if (op == "!=")
            call.setBool(false);
        else
            call.setBool(true);
        return;
    }
    else if (call.isNull(0) || call.isNull(1)) {
        static if (op == "!=")
            call.setBool(true);
        else
            call.setBool(false);
        return;
    }
    mixin("call.setBool(call.get" ~ t1 ~ "(0) " ~ op ~ " call.get" ~ t2 ~ "(1));");
}

private void _opComparison(string op, string t1, string t2)(GrCall call) {
    if (call.isNull(0) || call.isNull(1)) {
        call.setBool(false);
        return;
    }
    mixin("call.setBool(call.get" ~ t1 ~ "(0) " ~ op ~ " call.get" ~ t2 ~ "(1));");
}
