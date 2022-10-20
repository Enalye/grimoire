/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.optional;

import grimoire.compiler, grimoire.runtime, grimoire.assembly;
import grimoire.stdlib.util;

void grLoadStdLibOptional(GrLibDefinition library) {
    library.setModule(["std", "optional"]);

    library.addFunction(&_some, "some", [grAny("T")], [grOptional(grAny("T"))]);
    library.addFunction(&_expect, "expect", [
            grOptional(grAny("T")), grPure(grString)
        ], [grAny("T")]);
    library.addFunction(&_unwrap, "unwrap", [grOptional(grAny("T"))], [
            grAny("T")
        ]);
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
        library.addOperator(&_opUnary!(op, "Real"), op, [grOptional(grReal)], grOptional(grReal));
    }

    static foreach (op; ["+", "-", "*", "/", "%"]) {
        library.addOperator(&_opBinary!(op, "Int", "Int", "Int"), op,
            [grOptional(grInt), grOptional(grInt)], grOptional(grInt));

        library.addOperator(&_opBinary!(op, "Real", "Real", "Real"), op,
            [grOptional(grReal), grOptional(grReal)], grOptional(grReal));

        library.addOperator(&_opBinary!(op, "Real", "Int", "Real"), op,
            [grOptional(grReal), grOptional(grInt)], grOptional(grReal));

        library.addOperator(&_opBinary!(op, "Int", "Real", "Real"), op,
            [grOptional(grInt), grOptional(grReal)], grOptional(grReal));
    }

    library.addOperator(&_opUnary!("!", "Bool"), GrLibDefinition.Operator.not,
        [grOptional(grBool)], grOptional(grBool));

    static foreach (op; ["&&", "||"]) {
        library.addOperator(&_opBinary!(op, "Bool", "Bool", "Bool"), op,
            [grOptional(grBool), grOptional(grBool)], grOptional(grBool));
    }

    static foreach (op; ["==", "!="]) {
        library.addOperator(&_opEquality!(op, "Bool", "Bool"), op,
            [grOptional(grBool), grOptional(grBool)], grBool);

        library.addOperator(&_opEquality!(op, "Int", "Int"), op,
            [grOptional(grInt), grOptional(grInt)], grBool);

        library.addOperator(&_opEquality!(op, "Real", "Real"), op,
            [grOptional(grReal), grOptional(grReal)], grBool);

        library.addOperator(&_opEquality!(op, "Int", "Real"), op,
            [grOptional(grInt), grOptional(grReal)], grBool);

        library.addOperator(&_opEquality!(op, "Real", "Int"), op,
            [grOptional(grReal), grOptional(grInt)], grBool);
    }

    static foreach (op; [">", "<", ">=", "<="]) {
        library.addOperator(&_opComparison!(op, "Int", "Int"), op,
            [grOptional(grInt), grOptional(grInt)], grBool);

        library.addOperator(&_opComparison!(op, "Real", "Real"), op,
            [grOptional(grReal), grOptional(grReal)], grBool);

        library.addOperator(&_opComparison!(op, "Int", "Real"), op,
            [grOptional(grInt), grOptional(grReal)], grBool);

        library.addOperator(&_opComparison!(op, "Real", "Int"), op,
            [grOptional(grReal), grOptional(grInt)], grBool);
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
