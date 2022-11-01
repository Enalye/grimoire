/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.list;

import std.range;
import grimoire.assembly, grimoire.compiler, grimoire.runtime;
import grimoire.stdlib.util;

void grLoadStdLibList(GrLibDefinition library) {
    library.setModule(["std", "list"]);

    library.setModuleInfo(GrLocale.fr_FR, "Type de base.");
    library.setModuleInfo(GrLocale.en_US, "Built-in type.");

    library.setModuleDescription(GrLocale.fr_FR,
        "list est une collection de valeurs d’un même type.");
    library.setModuleDescription(GrLocale.en_US,
        "list is a collection of values of the same type.");

    library.setDescription(GrLocale.fr_FR, "Retourne une copie d’`lst`.");
    library.setDescription(GrLocale.en_US, "Returns a copy of `lst`.");
    library.setParameters(GrLocale.fr_FR, ["lst"]);
    library.setParameters(GrLocale.en_US, ["lst"]);
    library.addFunction(&_copy, "copy", [grPure(grList(grAny("T")))], [
            grList(grAny("T"))
        ]);

    library.setDescription(GrLocale.fr_FR, "Renvoie la taille d’`lst`.");
    library.setDescription(GrLocale.en_US, "Returns the size of `lst`.");
    library.addFunction(&_size, "size", [grPure(grList(grAny("T")))], [grInt]);

    library.setDescription(GrLocale.fr_FR, "Redimmensionne la `lst`.
Si `taille` dépasse la taille d’`lst`, l’exédent est initialisé à `défaut`.");
    library.setDescription(GrLocale.en_US, "Resize `lst`.
If `size` is greater than the size of `lst`, the rest is filled with `default`.");
    library.setParameters(GrLocale.fr_FR, ["lst", "taille", "défaut"]);
    library.setParameters(GrLocale.en_US, ["lst", "size", "default"]);
    library.addFunction(&_resize, "resize", [
            grList(grAny("T")), grInt, grAny("T")
        ]);

    library.setDescription(GrLocale.fr_FR, "Renvoie `true` si la `lst` ne contient rien.");
    library.setDescription(GrLocale.en_US, "Returns `true` if `lst` contains nothing.");
    library.setParameters(GrLocale.fr_FR, ["lst"]);
    library.setParameters(GrLocale.en_US, ["lst"]);
    library.addFunction(&_isEmpty, "isEmpty", [grPure(grList(grAny("T")))], [
            grBool
        ]);

    library.setDescription(GrLocale.fr_FR, "Remplace le contenu d’`lst` par `valeur`.");
    library.setDescription(GrLocale.en_US, "Replace the content of `lst` by `value`.");
    library.setParameters(GrLocale.fr_FR, ["lst", "valeur"]);
    library.setParameters(GrLocale.en_US, ["lst", "value"]);
    library.addFunction(&_fill, "fill", [grList(grAny("T")), grAny("T")]);

    library.setDescription(GrLocale.fr_FR, "Vide la `lst`.");
    library.setDescription(GrLocale.en_US, "Cleanup `lst`.");
    library.setParameters(GrLocale.fr_FR, ["lst"]);
    library.setParameters(GrLocale.en_US, ["lst"]);
    library.addFunction(&_clear, "clear", [grList(grAny("T"))]);

    library.setDescription(GrLocale.fr_FR, "Retourne l’élément à l’`index` indiqué, s’il existe.
Sinon, retourne `null(T)`.
Si `index` est négatif, l’`index` est calculé à partir de la fin d’`lst`.");
    library.setDescription(GrLocale.en_US, "Returns the element at `index`'s position.
If it doesn't exist, returns `null(T)`.
If `index` is negative, `index` is calculated from the back of `lst`.");
    library.setParameters(GrLocale.fr_FR, ["lst", "index"]);
    library.setParameters(GrLocale.en_US, ["lst", "index"]);
    library.addFunction(&_get, "get", [grPure(grList(grAny("T"))), grInt],
        [grOptional(grAny("T"))]);

    library.setDescription(GrLocale.fr_FR, "Retourne l’élément à l’`index` indiqué, s’il existe.
Sinon, retourne la valeur par `défaut`.
Si `index` est négatif, l’`index` est calculé à partir de la fin d’`lst`.");
    library.setDescription(GrLocale.en_US, "Returns the element at `index`'s position.
If it doesn't exist, returns the `default` value.
If `index` is negative, `index` is calculated from the back of `lst`.");
    library.setParameters(GrLocale.fr_FR, ["lst", "index", "défaut"]);
    library.setParameters(GrLocale.en_US, ["lst", "index", "default"]);
    library.addFunction(&_getOr, "getOr", [
            grPure(grList(grAny("T"))), grInt, grAny("T")
        ], [grAny("T")]);

    library.setDescription(GrLocale.fr_FR, "Ajoute `valeur` en début de `lst`.");
    library.setDescription(GrLocale.en_US, "Prepends `value` to the front of `lst`.");
    library.setParameters(GrLocale.fr_FR, ["lst", "valeur"]);
    library.setParameters(GrLocale.en_US, ["lst", "value"]);
    library.addFunction(&_unshift, "unshift", [grList(grAny("T")), grAny("T")]);

    library.setDescription(GrLocale.fr_FR, "Ajoute `valeur` en fin de `lst`.");
    library.setDescription(GrLocale.en_US, "Appends `value` to the back of `lst`.");
    library.addFunction(&_push, "push", [grList(grAny("T")), grAny("T")]);

    library.setDescription(GrLocale.fr_FR, "Retire le premier élément d’`lst` et les retourne.
S’il n’existe pas, retourne `null(T)`.");
    library.setDescription(GrLocale.en_US, "Removes the first element of `lst` and returns it.
If it doesn't exist, returns `null(T)`.");
    library.setParameters(GrLocale.fr_FR, ["lst"]);
    library.setParameters(GrLocale.en_US, ["lst"]);
    library.addFunction(&_shift, "shift", [grList(grAny("T"))], [
            grOptional(grAny("T"))
        ]);

    library.setDescription(GrLocale.fr_FR, "Retire le dernier élément d’`lst` et le retourne.
S’il n’existe pas, retourne `null(T)`.");
    library.setDescription(GrLocale.en_US, "Removes the last element of `lst` and returns it.
If it doesn't exist, returns `null(T)`.");
    library.addFunction(&_pop, "pop", [grList(grAny("T"))], [
            grOptional(grAny("T"))
        ]);

    library.setDescription(GrLocale.fr_FR,
        "Retire les premiers `quantité` éléments d’`lst` et les retourne.");
    library.setDescription(GrLocale.en_US,
        "Removes the first `quantity` elements from `lst` and returns them.");
    library.setParameters(GrLocale.fr_FR, ["lst", "quantité"]);
    library.setParameters(GrLocale.en_US, ["lst", "quantity"]);
    library.addFunction(&_shift1, "shift", [grList(grAny("T")), grInt], [
            grList(grAny("T"))
        ]);

    library.setDescription(GrLocale.fr_FR,
        "Retire `quantité` éléments d’`lst` et les retourne.");
    library.setDescription(GrLocale.en_US,
        "Removes `quantity` elements from `lst` and returns them.");
    library.addFunction(&_pop1, "pop", [grList(grAny("T")), grInt], [
            grList(grAny("T"))
        ]);

    library.setDescription(GrLocale.fr_FR, "Retourne le premier élément d’`lst`.
S’il n’existe pas, retourne `null(T)`.");
    library.setDescription(GrLocale.en_US, "Returns the first element of `lst`.
If it doesn't exist, returns `null(T)`.");
    library.setParameters(GrLocale.fr_FR, ["lst"]);
    library.setParameters(GrLocale.en_US, ["lst"]);
    library.addFunction(&_first, "first", [grPure(grList(grAny("T")))], [
            grOptional(grAny("T"))
        ]);

    library.setDescription(GrLocale.fr_FR, "Returne le dernier élément d’`lst`.
S’il n’existe pas, retourne `null(T)`.");
    library.setDescription(GrLocale.en_US, "Returns the last element of `lst`.
If it doesn't exist, returns `null(T)`.");
    library.addFunction(&_last, "last", [grPure(grList(grAny("T")))], [
            grOptional(grAny("T"))
        ]);

    library.setDescription(GrLocale.fr_FR, "Retire l’élément à l’`index` spécifié.");
    library.setDescription(GrLocale.en_US, "Removes the element at the specified `index`.");
    library.setParameters(GrLocale.fr_FR, ["lst", "index"]);
    library.setParameters(GrLocale.en_US, ["lst", "index"]);
    library.addFunction(&_remove, "remove", [grList(grAny("T")), grInt]);

    library.setDescription(GrLocale.fr_FR,
        "Retire les éléments de `indexDébut` à `indexFin` inclus.");
    library.setDescription(GrLocale.en_US,
        "Removes the elements from `startIndex` to `endIndex` included.");
    library.setParameters(GrLocale.fr_FR, ["lst", "indexDébut", "indexFin"]);
    library.setParameters(GrLocale.en_US, ["lst", "startIndex", "endIndex"]);
    library.addFunction(&_remove2, "remove", [grList(grAny("T")), grInt, grInt]);

    library.setDescription(GrLocale.fr_FR,
        "Retourne une portion d’`lst` de `indexDébut` jusqu’à `indexFin` inclus.");
    library.setDescription(GrLocale.en_US,
        "Returns a slice of `lst` from `startIndex` to `endIndex` included.");
    library.addFunction(&_slice, "slice", [
            grPure(grList(grAny("T"))), grInt, grInt
        ], [grList(grAny("T"))]);

    library.setDescription(GrLocale.fr_FR, "Retourne l’inverse d’`lst`.");
    library.setDescription(GrLocale.en_US, "Returns an inverted version of `lst`.");
    library.setParameters(GrLocale.fr_FR, ["lst"]);
    library.setParameters(GrLocale.en_US, ["lst"]);
    library.addFunction(&_reverse, "reverse", [grPure(grList(grAny("T")))], [
            grList(grAny("T"))
        ]);

    library.setDescription(GrLocale.fr_FR, "Insère `valeur` dans la `lst` à l’`index` spécifié.
Si `index` dépasse la taille d’`lst`, `valeur` est ajouté en fin de `lst`.
Si `index` est négatif, l’`index` est calculé à partir de la fin d’`lst`.");
    library.setDescription(GrLocale.en_US, "Insert `value` in `lst` at the specified `index`.
If `index` is greater than the size of `lst`, `value` is appended at the back of `lst`.
If `index` is negative, `index` is calculated from the back of `lst`.");
    library.setParameters(GrLocale.fr_FR, ["lst", "index", "valeur"]);
    library.setParameters(GrLocale.en_US, ["lst", "index", "value"]);
    library.addFunction(&_insert, "insert", [
            grList(grAny("T")), grInt, grAny("T")
        ]);

    library.setDescription(GrLocale.fr_FR,
        "Retourne la première occurence de `valeur` dans la `lst` à partir d’`index`.
Si `valeur  n’existe pas, `null(int)` est renvoyé.
Si `index` est négatif, l’`index` est calculé à partir de la fin d’`lst`.");
    library.setDescription(GrLocale.en_US,
        "Returns the first occurence of `value` in `lst`, starting from `index`.
If `value` does't exist, `null(int) is returned.
If `index` is negative, `index` is calculated from the back of `lst`.");
    library.setParameters(GrLocale.fr_FR, ["lst", "valeur"]);
    library.setParameters(GrLocale.en_US, ["lst", "value"]);
    library.addFunction(&_indexOf, "indexOf", [
            grPure(grList(grAny("T"))), grPure(grAny("T"))
        ], [grOptional(grInt)]);

    library.setDescription(GrLocale.fr_FR,
        "Retourne la dernière occurence de `valeur` dans la `lst` à partir d’`index`.
Si `valeur  n’existe pas, `null(int)` est renvoyé.
Si `index` est négatif, l’`index` est calculé à partir de la fin d’`lst`.");
    library.setDescription(GrLocale.en_US,
        "Returns the last occurence of `value` in `lst`, starting from `index`.
If `value` does't exist, `null(int) is returned.
If `index` is negative, `index` is calculated from the back of `lst`.");
    library.addFunction(&_lastIndexOf, "lastIndexOf",
        [grPure(grList(grAny("T"))), grPure(grAny("T"))], [grOptional(grInt)]);

    library.setDescription(GrLocale.fr_FR,
        "Renvoie `true` si `valeur` est présent dans la `lst`.");
    library.setDescription(GrLocale.en_US, "Returns `true` if `value` exists inside `lst`.");
    library.addFunction(&_contains, "contains", [
            grPure(grList(grAny("T"))), grPure(grAny("T"))
        ], [grBool]);

    library.setDescription(GrLocale.fr_FR, "Trie la `lst`.");
    library.setDescription(GrLocale.en_US, "Sorts `lst`.");
    library.setParameters(GrLocale.fr_FR, ["lst"]);
    library.setParameters(GrLocale.en_US, ["lst"]);
    library.addFunction(&_sort_!"int", "sort", [grList(grInt)]);
    library.addFunction(&_sort_!"real", "sort", [grList(grReal)]);
    library.addFunction(&_sort_!"string", "sort", [grList(grString)]);

    library.setDescription(GrLocale.fr_FR, "Itère sur une liste.");
    library.setDescription(GrLocale.en_US, "Iterate on a list.");
    GrType iteratorType = library.addNative("ListIterator", ["T"]);

    library.setDescription(GrLocale.fr_FR,
        "Returne un itérateur permettant d’itérer sur chaque élément d’`lst`.");
    library.setDescription(GrLocale.en_US,
        "Returns an iterator that iterate through each element of `lst`.");
    library.setParameters(GrLocale.fr_FR, ["lst"]);
    library.setParameters(GrLocale.en_US, ["lst"]);
    library.addFunction(&_each, "each", [grList(grAny("T"))], [iteratorType]);

    library.setDescription(GrLocale.fr_FR, "Avance l’itérateur à l’élément suivant.");
    library.setDescription(GrLocale.en_US, "Advance the iterator to the next element.");
    library.setParameters(GrLocale.fr_FR, ["itérateur"]);
    library.setParameters(GrLocale.en_US, ["iterator"]);
    library.addFunction(&_next, "next", [iteratorType], [grOptional(grAny("T"))]);
}

private void _copy(GrCall call) {
    call.setList(call.getList(0));
}

private void _size(GrCall call) {
    call.setInt(call.getList(0).size());
}

private void _resize(GrCall call) {
    GrList list = call.getList(0);
    const GrInt size = call.getInt(1);
    if (size < 0) {
        call.raise("ArgumentError");
        return;
    }
    list.resize(size, call.getValue(2));
}

private void _isEmpty(GrCall call) {
    const GrList list = call.getList(0);
    call.setBool(list.isEmpty());
}

private void _fill(GrCall call) {
    GrList list = call.getList(0);
    GrValue value = call.getValue(1);
    for (GrInt index; index < list.size(); ++index)
        list[index] = value;
}

private void _clear(GrCall call) {
    GrList list = call.getList(0);
    list.clear();
}

private void _get(GrCall call) {
    GrList list = call.getList(0);
    const GrInt idx = call.getInt(1);
    if (idx >= list.size) {
        call.setNull();
        return;
    }
    call.setValue(list[idx]);
}

private void _getOr(GrCall call) {
    GrList list = call.getList(0);
    const GrInt idx = call.getInt(1);
    if (idx >= list.size) {
        call.setValue(call.getValue(2));
        return;
    }
    call.setValue(list[idx]);
}

private void _unshift(GrCall call) {
    GrList list = call.getList(0);
    list.unshift(call.getValue(1));
}

private void _push(GrCall call) {
    GrList list = call.getList(0);
    list.push(call.getValue(1));
}

private void _shift(GrCall call) {
    GrList list = call.getList(0);
    if (!list.size()) {
        call.setNull();
        return;
    }
    call.setValue(list.shift());
}

private void _pop(GrCall call) {
    GrList list = call.getList(0);
    if (list.isEmpty()) {
        call.setNull();
        return;
    }
    call.setValue(list.pop());
}

private void _shift1(GrCall call) {
    GrList list = call.getList(0);
    GrInt size = call.getInt(1);
    if (size < 0) {
        call.raise("IndexError");
        return;
    }
    call.setList(list.shift(size));
}

private void _pop1(GrCall call) {
    GrList list = call.getList(0);
    GrInt size = call.getInt(1);
    if (size < 0) {
        call.raise("IndexError");
        return;
    }
    call.setList(list.pop(size));
}

private void _first(GrCall call) {
    GrList list = call.getList(0);
    if (!list.size()) {
        call.setNull();
        return;
    }
    call.setValue(list.first());
}

private void _last(GrCall call) {
    GrList list = call.getList(0);
    if (!list.size()) {
        call.setNull();
        return;
    }
    call.setValue(list.last());
}

private void _remove(GrCall call) {
    GrList list = call.getList(0);
    GrInt index = call.getInt(1);
    list.remove(index);
}

private void _remove2(GrCall call) {
    GrList list = call.getList(0);
    GrInt index1 = call.getInt(1);
    GrInt index2 = call.getInt(2);
    list.remove(index1, index2);
}

private void _slice(GrCall call) {
    GrList list = call.getList(0);
    GrInt index1 = call.getInt(1);
    GrInt index2 = call.getInt(2);
    call.setList(list.slice(index1, index2));
}

private void _reverse(GrCall call) {
    GrList list = call.getList(0);
    call.setList(list.reverse());
}

private void _insert(GrCall call) {
    GrList list = call.getList(0);
    GrInt index = call.getInt(1);
    GrValue value = call.getValue(2);
    list.insert(index, value);
}

private void _sort_(string T)(GrCall call) {
    GrList list = call.getList(0);
    static if (T == "int")
        list.sortByInt();
    else static if (T == "real")
        list.sortByReal();
    else static if (T == "string")
        list.sortByString();
}

private void _indexOf(GrCall call) {
    GrList list = call.getList(0);
    GrValue value = call.getValue(1);
    const GrInt index = list.indexOf(value);
    if (index < 0) {
        call.setNull();
        return;
    }
    call.setInt(index);
}

private void _lastIndexOf(GrCall call) {
    GrList list = call.getList(0);
    GrValue value = call.getValue(1);
    const GrInt index = list.lastIndexOf(value);
    if (index < 0) {
        call.setNull();
        return;
    }
    call.setInt(index);
}

private void _contains(GrCall call) {
    GrList list = call.getList(0);
    GrValue value = call.getValue(1);
    call.setBool(list.contains(value));
}

private final class ListIterator {
    GrValue[] list;
    size_t index;
}

private void _each(GrCall call) {
    GrList list = call.getList(0);
    ListIterator iter = new ListIterator;
    foreach (GrValue element; list.getValues()) {
        if (!element.isNull)
            iter.list ~= element;
    }
    call.setNative(iter);
}

private void _next(GrCall call) {
    ListIterator iter = call.getNative!(ListIterator)(0);
    if (iter.index >= iter.list.length) {
        call.setNull();
        return;
    }
    call.setValue(iter.list[iter.index]);
    iter.index++;
}
