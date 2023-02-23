/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.runtime.channel;

import std.exception : enforce;

import grimoire.assembly;
import grimoire.runtime.value;

/// Canal permettant la communication synchrone entre tâches
final class GrChannel {
    /// Le canal est actif
    bool isOwned = true;

    private {
        GrValue[] _buffer;
        uint _size, _capacity;
        bool _isReceiverReady;
    }

    @property {
        /// Vérifie si le canal peut recevoir une nouvelle valeur
        bool canSend() const {
            /*if (_capacity == 1u)
                return _isReceiverReady && _size < 1u;
            else*/
            return _size < _capacity;
        }

        /// Vérifie si le canal peut renvoyer une nouvelle valeur
        bool canReceive() const {
            return _size > 0u;
        }

        /// Nombre de valeur que possède le canal
        uint size() const {
            return _size;
        }

        /// Nombre maximum de valeur que peut posséder le canal
        uint capacity() const {
            return _capacity;
        }

        /// Le canal est-il vide ?
        bool isEmpty() const {
            return _size == 0u;
        }

        /// Le canal est-il plein ?
        bool isFull() const {
            return _size == _capacity;
        }

        /// Le contenu du buffer
        GrValue[] data() {
            return _buffer;
        }
    }

    this(uint buffSize = 1u) {
        _capacity = buffSize;
    }

    /// À appeler après avoir vérifié `canSend()` avant.
    void send()(auto ref GrValue value) {
        enforce(_size != _capacity /* || (_capacity == 1u && !_isReceiverReady)*/ ,
            "attempting to write on a full channel");

        _buffer ~= value;
        _size++;
    }

    /// À appeler après avoir vérifié `canReceive()` avant.
    GrValue receive() {
        enforce(_size != 0, "attempting to read on an empty channel");

        GrValue value = _buffer[0];
        _buffer = _buffer[1 .. $];
        _size--;
        //_isReceiverReady = false;
        return value;
    }

    /// Obsolète
    void setReceiverReady() {
        _isReceiverReady = true;
    }
}
