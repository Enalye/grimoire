/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.runtime.channel;

alias GrIntChannel = GrChannel!int;
alias GrFloatChannel = GrChannel!float;
alias GrStringChannel = GrChannel!string;
alias GrObjectChannel = GrChannel!(void*);

/**
A pipe that allow synchronised communication between coroutines.
*/
final class GrChannel(T) {
    /// The channel is active.
    bool isOwned = true;

    private {
        T[] _buffer;
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
            if(_capacity == 1u)
                return _isReceiverReady && _size < 1u;
            else
                return _size < _capacity;
        }

        /**
        You can receive whenever there is a value stored
        without being blocked.
        */
        bool canReceive() const { return _size > 0u; }
    }

    /// Fixed size buffer.
    this(uint buffSize) {
        _capacity = buffSize;
    }

    /// Always check canSend() before.
    void send(ref T value) {
        if(_size == _capacity || (_capacity == 1u && !_isReceiverReady))
            throw new Exception("Attempt to write on a full channel");
        _buffer ~= value;
        _size ++;
    }
    
    /// Always check canReceive() before.
    T receive() {
        if(_size == 0)
            throw new Exception("Attempt to read an empty channel");
        T value = _buffer[0];
        _buffer = _buffer[1.. $];
        _size --;
        _isReceiverReady = false;
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