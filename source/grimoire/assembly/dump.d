/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.assembly.dump;

import std.conv : to;
import std.string : leftJustify;

import grimoire.compiler;
import grimoire.assembly.bytecode;

private string[] instructions = [
    "nop", "throw", "try", "catch", "kill", "exit", "yield", "task", "atask",
    "new", "chan.i", "chan.f", "chan.s", "chan.o", "snd.i", "snd.f", "snd.s",
    "snd.o", "rcv.i", "rcv.f", "rcv.s", "rcv.o", "select_start", "select_end",
    "chan_try", "chan_check", "shift", "lstore", "lstore2", "lload", "gstore",
    "gstore2", "gload", "rstore", "rstore2", "frstore", "frload", "frload2",
    "fload", "fload2", "const.i", "const.f", "const.b", "const.s", "meta",
    "null", "gpush", "gpop", "eq.i", "eq.f", "eq.s", "neq.i", "neq.f", "neq.s",
    "geq.i", "geq.f", "leq.i", "leq.f", "gt.i", "gt.f", "lt.i", "lt.f",
    "nnull.o", "and.i", "or.i", "not.i", "cat.s", "add.i", "add.f", "sub.i",
    "sub.f", "mul.i", "mul.f", "div.i", "div.f", "rem.i", "rem.f", "neg.i",
    "neg.f", "inc.i", "inc.f", "dec.i", "dec.f", "copy", "swap", "setup_it",
    "local", "call", "acall", "pcall", "ret", "unwind", "defer", "jmp", "jmp_eq",
    "jmp_neq", "array.i", "array.f", "array.s", "array.o", "len.i", "len.f",
    "len.s", "len.o", "idx.i", "idx.f", "idx.s", "idx.o", "idx2.i", "idx2.f",
    "idx2.s", "idx2.o", "idx3.i", "idx3.f", "idx3.s", "idx3.o", "cat.ni", "cat.nf",
    "cat.ns", "cat.no", "append.i", "append.f", "append.s", "append.o",
    "prepend.i", "prepend.f", "prepend.s", "prepend.o", "eq.ni", "eq.nf",
    "eq.ns", "neq.ni", "neq.nf", "neq.ns", "dbg_prfbegin", "dbg_prfend"
];

/// Dump the bytecode's instruction list in a pretty format.
string grDump(const GrBytecode bytecode) {
    /*writeln("\n----- VM DUMP ------");
    writeln("iconsts: ", bytecode.iconsts);
    writeln("rconsts: ", bytecode.rconsts);
    writeln("sconsts: ", bytecode.sconsts);
    writeln("\nOpcodes:");*/

    string result;
    uint i;
    foreach (uint opcode; bytecode.opcodes) {
        GrOpcode op = cast(GrOpcode) grGetInstructionOpcode(opcode);

        string line = leftJustify("[" ~ to!string(i) ~ "]", 10) ~ leftJustify(instructions[op], 15);
        if ((op == GrOpcode.task) || (op >= GrOpcode.localStore &&
                op <= GrOpcode.localLoad) || (op >= GrOpcode.globalStore && op <= GrOpcode.globalLoad) ||
            op == GrOpcode.globalPush || (op >= GrOpcode.localStack && op <= GrOpcode.call) ||
            (op == GrOpcode.new_) || (op >= GrOpcode.fieldRefLoad && op <= GrOpcode.fieldLoad2) ||
            (op >= GrOpcode.channel_int && op <= GrOpcode.channel_object) ||
            (op >= GrOpcode.array_int && op <= GrOpcode.array_object))
            line ~= to!string(grGetInstructionUnsignedValue(opcode));
        else if (op == GrOpcode.fieldRefStore)
            line ~= to!string(grGetInstructionSignedValue(opcode));
        else if (op == GrOpcode.shiftStack)
            line ~= to!string(grGetInstructionSignedValue(opcode));
        else if (op == GrOpcode.primitiveCall)
            line ~= to!string(grGetInstructionUnsignedValue(opcode));
        else if (op == GrOpcode.const_int)
            line ~= to!string(bytecode.iconsts[grGetInstructionUnsignedValue(opcode)]);
        else if (op == GrOpcode.const_real)
            line ~= to!string(bytecode.rconsts[grGetInstructionUnsignedValue(opcode)]);
        else if (op == GrOpcode.const_bool)
            line ~= (grGetInstructionUnsignedValue(opcode) ? "true" : "false");
        else if (op == GrOpcode.const_string || op == GrOpcode.const_meta ||
            op == GrOpcode.debugProfileBegin)
            line ~= "\"" ~ to!string(bytecode.sconsts[grGetInstructionUnsignedValue(opcode)]) ~ "\"";
        else if (op >= GrOpcode.jump && op <= GrOpcode.jumpNotEqual)
            line ~= to!string(i + grGetInstructionSignedValue(opcode));
        else if (op == GrOpcode.defer || op == GrOpcode.try_ ||
            op == GrOpcode.catch_ || op == GrOpcode.tryChannel)
            line ~= to!string(i + grGetInstructionSignedValue(opcode));

        i++;
        result ~= line ~ "\n";
    }
    return result;
}
