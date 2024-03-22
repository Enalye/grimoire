/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.library.queue;

import grimoire;

void grLoadStdLibQueue(GrModule library) {
    library.setModule("queue");

    library.setModuleInfo(GrLocale.fr_FR,
        "Une queue est une collection pouvant être manipulé par les deux bouts.");
    library.setModuleInfo(GrLocale.en_US,
        "A queue is a collection that can be manipulated on both ends.");

    library.setDescription(GrLocale.fr_FR,
        "Une queue est une collection pouvant être manipulé par les deux bouts.");
    library.setDescription(GrLocale.en_US,
        "A queue is a collection that can be manipulated on both ends.");
    GrType queueType = library.addNative("Queue", ["T"]);

    library.setDescription(GrLocale.fr_FR, "Itère sur les éléments d’une queue.");
    library.setDescription(GrLocale.en_US, "Iterate on the elements of a queue.");
    library.addNative("QueueIterator", ["T"]);

    library.addConstructor(&_new, queueType);

    library.setDescription(GrLocale.fr_FR, "Renvoie `true` si la queue est vide.");
    library.setDescription(GrLocale.en_US, "Returns `true` if the queue is empty.");
    library.setParameters(["queue"]);
    library.addFunction(&_isEmpty, "isEmpty", [grPure(queueType)], [grBool]);

    library.setDescription(GrLocale.fr_FR, "Ajoute `value` à la fin de la queue.");
    library.setDescription(GrLocale.en_US, "Appends `value` to the back of the queue.");
    library.setParameters(["queue", "value"]);
    library.addFunction(&_pushBack, "pushBack", [queueType, grAny("T")]);

    library.setDescription(GrLocale.fr_FR, "Retire le dernier élément de la queue et le retourne.
Si la queue est vide, retourne `null<T>`.");
    library.setDescription(GrLocale.en_US, "Removes the last element of the queue and returns it.
If the queue is empty, returns `null<T>`.");
    library.setParameters(["queue"]);
    library.addFunction(&_popBack, "popBack", [queueType], [
            grOptional(grAny("T"))
        ]);

    library.setDescription(GrLocale.fr_FR, "Retourne le premier élément de la queue.
Si la queue est vide, retourne `null<T>`.");
    library.setDescription(GrLocale.en_US, "Returns the first element of the queue.
If the queue is empty, returns `null<T>`.");
    library.addFunction(&_front, "front", [grPure(queueType)], [
            grOptional(grAny("T"))
        ]);

    library.setDescription(GrLocale.fr_FR, "Returne le dernier élément de la queue.
Si la queue est vide, retourne `null<T>`.");
    library.setDescription(GrLocale.en_US, "Returns the last element of the queue.
If the queue is empty, returns `null<T>`.");
    library.addFunction(&_back, "back", [grPure(queueType)], [
            grOptional(grAny("T"))
        ]);
}

final class GrQueue {
    private {
        final class Node {
            GrValue value;
            Node previous, next;
        }

        Node _front, _back;
    }

    @property {
        pragma(inline) bool isEmpty() const {
            return _back is null;
        }
    }

    pragma(inline) void push(GrValue value) {
        Node node = new Node;
        node.value = value;

        if (_front) {
            node.previous = _front;
            _front.next = node;
            _front = node;
        }
        else {
            _back = _front = node;
        }
    }

    pragma(inline) GrValue pop() {
        assert(_back);
        Node node = _back;
        _back = _back.next;
        return node.value;
    }

    pragma(inline) GrValue front() {
        assert(_front);
        return _front.value;
    }

    pragma(inline) GrValue back() {
        assert(_back);
        return _back.value;
    }
}

private void _new(GrCall call) {
    call.setNative(new GrQueue);
}

private void _isEmpty(GrCall call) {
    const GrQueue queue = call.getNative!GrQueue(0);
    call.setBool(queue.isEmpty);
}

private void _pushBack(GrCall call) {
    GrQueue queue = call.getNative!GrQueue(0);
    queue.push(call.getValue(1));
}

private void _popBack(GrCall call) {
    GrQueue queue = call.getNative!GrQueue(0);
    if (queue.isEmpty) {
        call.setNull();
        return;
    }
    call.setValue(queue.pop());
}

private void _front(GrCall call) {
    GrQueue queue = call.getNative!GrQueue(0);
    if (queue.isEmpty) {
        call.setNull();
        return;
    }
    call.setValue(queue.front());
}

private void _back(GrCall call) {
    GrQueue queue = call.getNative!GrQueue(0);
    if (queue.isEmpty) {
        call.setNull();
        return;
    }
    call.setValue(queue.back());
}
