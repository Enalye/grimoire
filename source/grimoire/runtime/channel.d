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

    /// True when the value has been sent but not yet received.
    bool hasSlot;

    /// Payload of the channel
    T value;
}