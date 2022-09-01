/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.runtime.channel;

import grimoire.assembly;

/**
A pipe that allow synchronised communication between coroutines.
*/
final class GrChannel {
    /// The channel is active.
    bool isOwned = true;

    private {
        GrValue[] _buffer;
        uint _size, _capacity;
        bool _isReceiverReady;
    }

    @property {
        /**
        On a channel of size 1, the sender is blocked
        until something tells him he is ready to receive the value.

        For any other size, the sender is never blocked
        until the buffer is full.
        */
        bool canSend() const {
            /*if (_capacity == 1u)
                return _isReceiverReady && _size < 1u;
            else*/
                return _size < _capacity;
        }

        /**
        You can receive whenever there is a value stored
        without being blocked.
        */
        bool canReceive() const {
            return _size > 0u;
        }

        /// Number of values the channel is currently storing
        uint size() const {
            return _size;
        }

        /// Maximum number of values the channel can store
        uint capacity() const {
            return _capacity;
        }

        /// Is the channel empty ?
        bool isEmpty() const {
            return _size == 0u;
        }

        /// Is the channel full ?
        bool isFull() const {
            return _size == _capacity;
        }
    }

    /// Buffer of size 1.
    this() {
        _capacity = 1u;
    }

    /// Fixed size buffer.
    this(uint buffSize) {
        _capacity = buffSize;
    }

    /// Always check canSend() before.
    void send()(auto ref GrValue value) {
        if (_size == _capacity/* || (_capacity == 1u && !_isReceiverReady)*/)
            throw new Exception("Attempt to write on a full channel");
        _buffer ~= value;
        _size++;
    }

    /// Always check canReceive() before.
    GrValue receive() {
        if (_size == 0)
            throw new Exception("Attempt to read an empty channel");
        GrValue value = _buffer[0];
        _buffer = _buffer[1 .. $];
        _size--;
        //_isReceiverReady = false;
        return value;
    }

    /**
    Notify the senders that they can write to
    this channel because you are blocked on it.
    */
    void setReceiverReady() {
        _isReceiverReady = true;
    }
}
