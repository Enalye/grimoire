/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
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
        "Une liste est une collection de valeurs d’un même type.");
    library.setModuleDescription(GrLocale.en_US,
        "A list is a collection of values of the same type.");

    library.setDescription(GrLocale.fr_FR, "Retourne une copie de la liste.");
    library.setDescription(GrLocale.en_US, "Returns a copy of the list.");
    library.setParameters(GrLocale.fr_FR, ["self"]);
    library.setParameters(GrLocale.en_US, ["self"]);
    library.addFunction(&_copy, "copy", [grPure(grList(grAny("T")))], [
            grList(grAny("T"))
        ]);

    library.setDescription(GrLocale.fr_FR, "Renvoie la taille de la liste.");
    library.setDescription(GrLocale.en_US, "Returns the size of the list.");
    library.addFunction(&_size, "size", [grPure(grList(grAny("T")))], [grInt]);

    library.setDescription(GrLocale.fr_FR, "Redimmensionne la liste.
Si `len` est plus grand que la taille de la liste, l’exédent est initialisé avec `def`.");
    library.setDescription(GrLocale.en_US, "Resize the list.
If `len` is greater than the size of the list, the rest is filled with `def`.");
    library.setParameters(GrLocale.fr_FR, ["self", "len", "def"]);
    library.setParameters(GrLocale.en_US, ["self", "len", "def"]);
    library.addFunction(&_resize, "resize", [
            grList(grAny("T")), grInt, grAny("T")
        ]);

    library.setDescription(GrLocale.fr_FR, "Renvoie `true` si la liste est vide.");
    library.setDescription(GrLocale.en_US, "Returns `true` if the list is empty.");
    library.setParameters(GrLocale.fr_FR, ["self"]);
    library.setParameters(GrLocale.en_US, ["self"]);
    library.addFunction(&_isEmpty, "isEmpty", [grPure(grList(grAny("T")))], [
            grBool
        ]);

    library.setDescription(GrLocale.fr_FR, "Remplace le contenu de la liste par `value`.");
    library.setDescription(GrLocale.en_US, "Replace the content of the list by `value`.");
    library.setParameters(GrLocale.fr_FR, ["self", "value"]);
    library.setParameters(GrLocale.en_US, ["self", "value"]);
    library.addFunction(&_fill, "fill", [grList(grAny("T")), grAny("T")]);

    library.setDescription(GrLocale.fr_FR, "Vide la liste.");
    library.setDescription(GrLocale.en_US, "Clear the list.");
    library.setParameters(GrLocale.fr_FR, ["self"]);
    library.setParameters(GrLocale.en_US, ["self"]);
    library.addFunction(&_clear, "clear", [grList(grAny("T"))]);

    library.setDescription(GrLocale.fr_FR, "Retourne l’élément à l’index indiqué, s’il existe.
Sinon, retourne `null<T>`.
Un index négatif est calculé à partir de la fin de la liste.");
    library.setDescription(GrLocale.en_US, "Returns the element at index position.
If it doesn't exist, returns `null<T>`.
A negative index is calculated from the back of the list.");
    library.setParameters(GrLocale.fr_FR, ["self", "idx"]);
    library.setParameters(GrLocale.en_US, ["self", "idx"]);
    library.addFunction(&_get, "get", [grPure(grList(grAny("T"))), grInt],
        [grOptional(grAny("T"))]);

    library.setDescription(GrLocale.fr_FR, "Retourne l’élément à l’index indiqué, s’il existe.
Sinon, retourne la value par défaut `def`.
Un index négatif est calculé à partir de la fin de la liste.");
    library.setDescription(GrLocale.en_US, "Returns the element at index position.
If it doesn't exist, returns the default `def` value.
A negative index is calculated from the back of the list.");
    library.setParameters(GrLocale.fr_FR, ["self", "idx", "def"]);
    library.setParameters(GrLocale.en_US, ["self", "idx", "def"]);
    library.addFunction(&_getOr, "getOr", [
            grPure(grList(grAny("T"))), grInt, grAny("T")
        ], [grAny("T")]);

    library.setDescription(GrLocale.fr_FR, "Ajoute `value` au début de la liste.");
    library.setDescription(GrLocale.en_US, "Prepends `value` to the front of the list.");
    library.setParameters(GrLocale.fr_FR, ["self", "value"]);
    library.setParameters(GrLocale.en_US, ["self", "value"]);
    library.addFunction(&_pushFront, "pushFront", [
            grList(grAny("T")), grAny("T")
        ]);

    library.setDescription(GrLocale.fr_FR, "Ajoute `value` à la fin de la liste.");
    library.setDescription(GrLocale.en_US, "Appends `value` to the back of the list.");
    library.addFunction(&_pushBack, "pushBack", [grList(grAny("T")), grAny("T")]);

    library.setDescription(GrLocale.fr_FR, "Retire le premier élément de la liste et les retourne.
S’il n’existe pas, retourne `null<T>`.");
    library.setDescription(GrLocale.en_US, "Removes the first element of the list and returns it.
If it doesn't exist, returns `null<T>`.");
    library.setParameters(GrLocale.fr_FR, ["self"]);
    library.setParameters(GrLocale.en_US, ["self"]);
    library.addFunction(&_popFront, "popFront", [grList(grAny("T"))], [
            grOptional(grAny("T"))
        ]);

    library.setDescription(GrLocale.fr_FR, "Retire le dernier élément de la liste et le retourne.
S’il n’existe pas, retourne `null<T>`.");
    library.setDescription(GrLocale.en_US, "Removes the last element of the list and returns it.
If it doesn't exist, returns `null<T>`.");
    library.addFunction(&_popBack, "popBack", [grList(grAny("T"))], [
            grOptional(grAny("T"))
        ]);

    library.setDescription(GrLocale.fr_FR,
        "Retire les N premiers éléments de la liste et les retourne.");
    library.setDescription(GrLocale.en_US,
        "Removes the first N elements from the list and returns them.");
    library.setParameters(GrLocale.fr_FR, ["self", "count"]);
    library.setParameters(GrLocale.en_US, ["self", "count"]);
    library.addFunction(&_popFront_count, "popFront", [
            grList(grAny("T")), grUInt
        ], [grList(grAny("T"))]);

    library.setDescription(GrLocale.fr_FR,
        "Retire les N derniers éléments de la liste et les retourne.");
    library.setDescription(GrLocale.en_US,
        "Removes the last N elements from the list and returns them.");
    library.addFunction(&_popBack_count, "popBack", [grList(grAny("T")),
            grInt], [grList(grAny("T"))]);

    library.setDescription(GrLocale.fr_FR, "Retourne le premier élément de la liste.
S’il n’existe pas, retourne `null<T>`.");
    library.setDescription(GrLocale.en_US, "Returns the first element of the list.
If it doesn't exist, returns `null<T>`.");
    library.setParameters(GrLocale.fr_FR, ["self"]);
    library.setParameters(GrLocale.en_US, ["self"]);
    library.addFunction(&_front, "front", [grPure(grList(grAny("T")))], [
            grOptional(grAny("T"))
        ]);

    library.setDescription(GrLocale.fr_FR, "Returne le dernier élément de la liste.
S’il n’existe pas, retourne `null<T>`.");
    library.setDescription(GrLocale.en_US, "Returns the last element of the list.
If it doesn't exist, returns `null<T>`.");
    library.addFunction(&_back, "back", [grPure(grList(grAny("T")))], [
            grOptional(grAny("T"))
        ]);

    library.setDescription(GrLocale.fr_FR, "Retire l’élément à l’index spécifié.
Un index négatif est calculé à partir de la fin de la liste.");
    library.setDescription(GrLocale.en_US, "Removes the element at the specified index.
A negative index is calculated from the back of the list.");
    library.setParameters(GrLocale.fr_FR, ["self", "idx"]);
    library.setParameters(GrLocale.en_US, ["self", "idx"]);
    library.addFunction(&_remove_idx, "remove", [grList(grAny("T")), grInt]);

    library.setDescription(GrLocale.fr_FR, "Retire les éléments de `start` à `end` inclus.
Un index négatif est calculé à partir de la fin de la liste.");
    library.setDescription(GrLocale.en_US, "Removes the elements from `start` to `end` included.
A negative index is calculated from the back of the list.");
    library.setParameters(GrLocale.fr_FR, ["self", "start", "end"]);
    library.setParameters(GrLocale.en_US, ["self", "start", "end"]);
    library.addFunction(&_remove_slice, "remove", [
            grList(grAny("T")), grInt, grInt
        ]);

    library.setDescription(GrLocale.fr_FR,
        "Retourne une portion de la liste de `start` jusqu’à `end` inclus.
Un index négatif est calculé à partir de la fin de la liste.");
    library.setDescription(GrLocale.en_US,
        "Returns a slice of the list from `start` to `end` included.
A negative index is calculated from the back of the list.");
    library.addFunction(&_slice, "slice", [
            grPure(grList(grAny("T"))), grInt, grInt
        ], [grList(grAny("T"))]);

    library.setDescription(GrLocale.fr_FR, "Retourne une version inversée de la liste.");
    library.setDescription(GrLocale.en_US, "Returns an inverted version of the list.");
    library.setParameters(GrLocale.fr_FR, ["self"]);
    library.setParameters(GrLocale.en_US, ["self"]);
    library.addFunction(&_reverse, "reverse", [grPure(grList(grAny("T")))], [
            grList(grAny("T"))
        ]);

    library.setDescription(GrLocale.fr_FR, "Insère `value` dans la liste à l’`index` spécifié.
Si `index` dépasse la taille de la liste, `value` est ajouté en fin de the list.
Un index négatif est calculé à partir de la fin de la liste.");
    library.setDescription(GrLocale.en_US, "Insert `value` in the list at the specified `index`.
If `index` is greater than the size of the list, `value` is appended at the back of the list.
A negative index is calculated from the back of the list.");
    library.setParameters(GrLocale.fr_FR, ["self", "idx", "value"]);
    library.setParameters(GrLocale.en_US, ["self", "idx", "value"]);
    library.addFunction(&_insert, "insert", [
            grList(grAny("T")), grInt, grAny("T")
        ]);

    library.setDescription(GrLocale.fr_FR,
        "Retourne la première occurence de `value` dans la liste à partir de l’index.
Si `value`  n’existe pas, `null<int>` est renvoyé.
Un index négatif est calculé à partir de la fin de la liste.");
    library.setDescription(GrLocale.en_US,
        "Returns the first occurence of `value` in the list, starting from the index.
If `value` does't exist, `null<int> is returned.
A negative index is calculated from the back of the list.");
    library.setParameters(GrLocale.fr_FR, ["self", "value"]);
    library.setParameters(GrLocale.en_US, ["self", "value"]);
    library.addFunction(&_find, "find", [
            grPure(grList(grAny("T"))), grPure(grAny("T"))
        ], [grOptional(grUInt)]);

    library.setDescription(GrLocale.fr_FR,
        "Retourne la dernière occurence de `value` dans la liste à partir de l’index.
Si `value`  n’existe pas, `null<int>` est renvoyé.
Un index négatif est calculé à partir de la fin de la liste.");
    library.setDescription(GrLocale.en_US,
        "Returns the last occurence of `value` in the list, starting from the index.
If `value` does't exist, `null<int> is returned.
A negative index is calculated from the back of the list.");
    library.addFunction(&_rfind, "rfind", [
            grPure(grList(grAny("T"))), grPure(grAny("T"))
        ], [grOptional(grUInt)]);

    library.setDescription(GrLocale.fr_FR, "Renvoie `true` si `value` est présent dans la liste.");
    library.setDescription(GrLocale.en_US, "Returns `true` if `value` exists inside the list.");
    library.addFunction(&_contains, "contains", [
            grPure(grList(grAny("T"))), grPure(grAny("T"))
        ], [grBool]);

    library.setDescription(GrLocale.fr_FR, "Trie la liste.");
    library.setDescription(GrLocale.en_US, "Sorts the list.");
    library.setParameters(GrLocale.fr_FR, ["self"]);
    library.setParameters(GrLocale.en_US, ["self"]);
    library.addFunction(&_sort_!"int", "sort", [grList(grInt)]);
    library.addFunction(&_sort_!"float", "sort", [grList(grFloat)]);
    library.addFunction(&_sort_!"string", "sort", [grList(grString)]);

    library.setDescription(GrLocale.fr_FR, "Itère sur une liste.");
    library.setDescription(GrLocale.en_US, "Iterate on a list.");
    GrType iteratorType = library.addNative("ListIterator", ["T"]);

    library.setDescription(GrLocale.fr_FR,
        "Returne un itérateur permettant d’itérer sur chaque élément de la liste.");
    library.setDescription(GrLocale.en_US,
        "Returns an iterator that iterate through each element of the list.");
    library.setParameters(GrLocale.fr_FR, ["self"]);
    library.setParameters(GrLocale.en_US, ["self"]);
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

private void _pushFront(GrCall call) {
    GrList list = call.getList(0);
    list.pushFront(call.getValue(1));
}

private void _pushBack(GrCall call) {
    GrList list = call.getList(0);
    list.pushBack(call.getValue(1));
}

private void _popFront(GrCall call) {
    GrList list = call.getList(0);
    if (list.isEmpty()) {
        call.setNull();
        return;
    }
    call.setValue(list.popFront());
}

private void _popBack(GrCall call) {
    GrList list = call.getList(0);
    if (list.isEmpty()) {
        call.setNull();
        return;
    }
    call.setValue(list.popBack());
}

private void _popFront_count(GrCall call) {
    GrList list = call.getList(0);
    GrUInt count = call.getUInt(1);

    call.setList(list.popFront(count));
}

private void _popBack_count(GrCall call) {
    GrList list = call.getList(0);
    GrUInt count = call.getUInt(1);

    call.setList(list.popBack(count));
}

private void _front(GrCall call) {
    GrList list = call.getList(0);

    if (list.isEmpty()) {
        call.setNull();
        return;
    }

    call.setValue(list.front());
}

private void _back(GrCall call) {
    GrList list = call.getList(0);

    if (list.isEmpty()) {
        call.setNull();
        return;
    }

    call.setValue(list.back());
}

private void _remove_idx(GrCall call) {
    GrList list = call.getList(0);
    GrInt index = call.getInt(1);

    list.remove(index);
}

private void _remove_slice(GrCall call) {
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
    else static if (T == "float")
        list.sortByFloat();
    else static if (T == "string")
        list.sortByString();
}

private void _find(GrCall call) {
    GrList list = call.getList(0);
    GrValue value = call.getValue(1);

    bool found;
    const GrUInt index = list.find(found, value);

    if (!found) {
        call.setNull();
        return;
    }

    call.setUInt(index);
}

private void _rfind(GrCall call) {
    GrList list = call.getList(0);
    GrValue value = call.getValue(1);

    bool found;
    const GrUInt index = list.rfind(found, value);

    if (!found) {
        call.setNull();
        return;
    }

    call.setUInt(index);
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
