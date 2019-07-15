module grimoire.runtime.channel;

import grimoire.runtime.variant;

alias GrIntChannel = GrChannel!int;
alias GrFloatChannel = GrChannel!float;
alias GrStringChannel = GrChannel!dstring;
alias GrVariantChannel = GrChannel!GrVariantValue;
alias GrObjectChannel = GrChannel!(void*);

final class GrChannel(T) {
    /// The channel is active.
    bool isOwned = true;

    private {
        T[] _buffer;
        uint _size, _capacity;
    }

    @property {
        bool canSend() const { return _size != _capacity; }
        bool canReceive() { return _size != 0; }
    }

    this(uint buffSize) {
        _capacity = buffSize;
    }

    void send(ref T value) {
        if(_size == _capacity)
            throw new Exception("Attemp to write on a full channel");
        _buffer ~= value;
        _size ++;     
    }

    T receive() {
        if(_size == 0)
            throw new Exception("Attemp to read an empty channel");
        T value = _buffer[0];
        _buffer = _buffer[1.. $];
        _size --;
        return value;
    }
}