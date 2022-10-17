/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.stdlib.queue;

import grimoire.assembly, grimoire.compiler, grimoire.runtime;
import grimoire.stdlib.util;

package(grimoire.stdlib) void grLoadStdLibQueue(GrLibrary library) {
    library.addNative("Queue", ["T"]);
    library.addNative("QueueIterator", ["T"]);

    GrType valueType = grAny("T");
    GrType queueType = grGetNativeType("Queue", [valueType]);

    library.addConstructor(&_new, queueType);

    library.addFunction(&_isEmpty, "isEmpty", [grPure(queueType)], [grBool]);

    library.addFunction(&_push, "push", [queueType, grAny("T")]);
    library.addFunction(&_pop, "pop", [queueType], [grOptional(grAny("T"))]);

    library.addFunction(&_front, "front", [grPure(queueType)], [
            grOptional(grAny("T"))
        ]);
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

private void _push(GrCall call) {
    GrQueue queue = call.getNative!GrQueue(0);
    queue.push(call.getValue(1));
}

private void _pop(GrCall call) {
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
