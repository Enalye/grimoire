/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.system;

import grimoire.compiler, grimoire.runtime, grimoire.assembly;
import grimoire.stdlib.util;

package void grLoadStdLibSystem(GrLibrary library) {
    library.addFunction(&_swap_2, "swap", [grAny("T1"), grAny("T2")], [
            grAny("T2"), grAny("T1")
        ]);

    GrType optionType = library.addForeign("Option", ["T"]);

    library.addFunction(&_wrap, "wrap", [grBool, grAny("T")], [optionType]);
    library.addFunction(&_expect, "expect", [grBool, grAny("T"), grPureString], [
            grAny("T")
        ]);
    library.addFunction(&_expectOption, "expect", [optionType, grPureString], [
            grAny("T")
        ]);
    library.addFunction(&_unwrap, "unwrap", [grBool, grAny("T")], [grAny("T")]);
    library.addFunction(&_unwrapOption, "unwrap", [optionType], [grAny("T")]);
    library.addFunction(&_unwrapOr, "unwrapOr", [grBool, grAny("T"), grAny("T")], [
            grAny("T")
        ]);
    library.addFunction(&_unwrapOptionOr, "unwrapOr", [optionType, grAny("T")], [
            grAny("T")
        ]);
    library.addFunction(&_some, "some", [grAny("T")], [optionType]);
    library.addFunction(&_none, "none", [], [optionType]);

    library.addFunction(&_typeOf, "typeOf", [grAny("T")], [grString]);
}

final class GrOption {
    GrBool hasValue;
    GrValue value;
}

private void _swap_2(GrCall call) {
    call.setValue(call.getValue(1));
    call.setValue(call.getValue(0));
}

private void _expect(GrCall call) {
    if (call.getBool(0))
        call.setValue(call.getValue(1));
    else
        call.raise(call.getString(2));
}

private void _expectOption(GrCall call) {
    GrOption option = call.getForeign!GrOption(0);
    if (!option) {
        call.raise("NullError");
        return;
    }
    if (option.hasValue)
        call.setValue(option.value);
    else
        call.raise(call.getString(1));
}

private void _wrap(GrCall call) {
    GrOption option = new GrOption;
    option.hasValue = call.getBool(0);
    option.value = call.getValue(1);
    call.setForeign(option);
}

private void _unwrap(GrCall call) {
    if (call.getBool(0))
        call.setValue(call.getValue(1));
    else
        call.raise("UnwrapError");
}

private void _unwrapOption(GrCall call) {
    GrOption option = call.getForeign!GrOption(0);
    if (!option) {
        call.raise("NullError");
        return;
    }
    if (option.hasValue)
        call.setValue(option.value);
    else
        call.raise("UnwrapError");
}

private void _unwrapOr(GrCall call) {
    call.setValue(call.getBool(0) ? call.getValue(1) : call.getValue(2));
}

private void _unwrapOptionOr(GrCall call) {
    GrOption option = call.getForeign!GrOption(0);
    if (!option) {
        call.raise("NullError");
        return;
    }
    call.setValue(option.hasValue ? option.value : call.getValue(1));
}

private void _some(GrCall call) {
    GrOption option = new GrOption;
    option.hasValue = true;
    option.value = call.getValue(0);
    call.setForeign(option);
}

private void _none(GrCall call) {
    GrOption option = new GrOption;
    option.hasValue = false;
    call.setForeign(option);
}

private void _typeOf(GrCall call) {
    call.setString(grGetPrettyType(grUnmangle(call.getInType(0))));
}
