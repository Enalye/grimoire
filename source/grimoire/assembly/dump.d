/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module grimoire.assembly.dump;

import std.conv: to;
import std.string: leftJustify;

import grimoire.compiler;
import grimoire.assembly.bytecode;

private string[] instructions = [
    "nop", "raise", "try", "catch",
    "kill", "killall", "yield", "task", "anon_task", "new",

    "chan.i", "chan.f", "chan.s", "chan.o",
    "snd.i", "snd.f", "snd.s", "snd.o",
    "rcv.i", "rcv.f", "rcv.s", "rcv.o",
    "select_start", "select_end", "chan_try", "chan_check",

    "shift.i", "shift.f", "shift.s", "shift.o",
    
    "lstore.i", "lstore.f", "lstore.s", "lstore.o",
    "lstore2.i", "lstore2.f", "lstore2.s", "lstore2.o",
    "lload.i", "lload.f", "lload.s", "lload.o",

    "gstore.i", "gstore.f", "gstore.s", "gstore.o",
    "gstore2.i", "gstore2.f", "gstore2.s", "gstore2.o",
    "gload.i", "gload.f", "gload.s", "gload.o",
    
    "rstore.i", "rstore.f", "rstore.s", "rstore.o",
    "rstore2.i", "rstore2.f", "rstore2.s", "rstore2.o",

    "fstore.i", "fstore.f", "fstore.s", "fstore.o",
    "fload",
    "fload.i", "fload.f", "fload.s", "fload.o",
    "fload2.i", "fload2.f", "fload2.s", "fload2.o",

    "const.i", "const.f", "const.b", "const.s", "meta",
    
    "gpush.i", "gpush.f", "gpush.s", "gpush.o",
    "gpop.i", "gpop.f", "gpop.s", "gpop.o",

    "eq.i", "eq.f", "eq.s",
    "neq.i", "neq.f", "neq.s",
    "geq.i", "geq.f",
    "leq.i", "leq.f",
    "gt.i", "gt.f",
    "lt.i", "lt.f",
    "nnull.o",

    "and.i", "or.i", "not.i",
    "cat.s",
    "add.i", "add.f",
    "sub.i", "sub.f",
    "mul.i", "mul.f",
    "div.i", "div.f",
    "rem.i", "rem.f",
    "neg.i", "neg.f",
    "inc.i", "inc.f",
    "dec.i", "dec.f",
    
    "swap.i", "swap.f", "swap.s", "swap.o",

    "setup_it",

    "loc.i", "loc.f", "loc.s", "loc.o",
    "call", "acall", "pcall",
    "ret", "unwind", "defer",
    "jmp", "jmp_eq", "jmp_neq",

    "array.i", "array.f", "array.s", "array.o",
    "len.i", "len.f", "len.s", "len.o",
    "idx.i", "idx.f", "idx.s", "idx.o",
    "idx2.i", "idx2.f", "idx2.s", "idx2.o",
    "idx3.i", "idx3.f", "idx3.s", "idx3.o",

    "cat.ni", "cat.nf", "cat.ns", "cat.no",
    "append.i", "append.f", "append.s", "append.o",
    "prepend.i", "prepend.f", "prepend.s", "prepend.o",

    "eq.ni", "eq.nf", "eq.ns",
    "neq.ni", "neq.nf", "neq.ns",

    "dbg_prfbegin", "dbg_prfend"
];

/// Dump the bytecode's instruction list in a pretty format.
string grDump(GrData data, GrBytecode bytecode) {
    /*writeln("\n----- VM DUMP ------");
    writeln("iconsts: ", bytecode.iconsts);
    writeln("fconsts: ", bytecode.fconsts);
    writeln("sconsts: ", bytecode.sconsts);
    writeln("\nOpcodes:");*/

    string result;
    uint i;
    foreach(uint opcode; bytecode.opcodes) {
        GrOpcode op = cast(GrOpcode)grGetInstructionOpcode(opcode);

        string line = leftJustify("[" ~ to!string(i) ~ "]", 10) ~ leftJustify(instructions[op], 15);
        if((op == GrOpcode.task) ||
            (op >= GrOpcode.localStore_Int && op <= GrOpcode.localLoad_Object) ||
            (op >= GrOpcode.globalStore_Int && op <= GrOpcode.globalLoad_Object) ||
            (op >= GrOpcode.globalPush_Int && op <= GrOpcode.globalPush_Object) ||
            (op >= GrOpcode.localStack_Int && op <= GrOpcode.call) ||
            (op == GrOpcode.new_) ||
            (op >= GrOpcode.fieldLoad && op <= GrOpcode.fieldLoad2_Object) ||
            (op >= GrOpcode.channel_Int && op <= GrOpcode.channel_Object) ||
            (op >= GrOpcode.array_Int && op <= GrOpcode.array_Object)
            )
            line ~= to!string(grGetInstructionUnsignedValue(opcode));
        else if(op >= GrOpcode.fieldStore_Int && op <= GrOpcode.fieldStore_Object)
            line ~= to!string(grGetInstructionSignedValue(opcode));
        else if(op >= GrOpcode.shiftStack_Int && op <= GrOpcode.shiftStack_Object)
            line ~= to!string(grGetInstructionSignedValue(opcode));
        else if(op == GrOpcode.primitiveCall)
            line ~= data.getPrimitiveDisplayById(grGetInstructionUnsignedValue(opcode));
        else if(op == GrOpcode.const_Int)
            line ~= to!string(bytecode.iconsts[grGetInstructionUnsignedValue(opcode)]);
        else if(op == GrOpcode.const_Float)
            line ~= to!string(bytecode.fconsts[grGetInstructionUnsignedValue(opcode)]);
        else if(op == GrOpcode.const_Bool)
            line ~= (grGetInstructionUnsignedValue(opcode) ? "true" : "false");
        else if(op == GrOpcode.const_String || op == GrOpcode.const_Meta || op == GrOpcode.debug_ProfileBegin)
            line ~= "\"" ~ to!string(bytecode.sconsts[grGetInstructionUnsignedValue(opcode)]) ~ "\"";
        else if(op >= GrOpcode.jump && op <= GrOpcode.jumpNotEqual)
            line ~= to!string(i + grGetInstructionSignedValue(opcode));
        else if(op == GrOpcode.defer || op == GrOpcode.try_ || op == GrOpcode.catch_ || op == GrOpcode.tryChannel)
            line ~= to!string(i + grGetInstructionSignedValue(opcode));

        i++;
        result ~= line ~ "\n";
    }
    return result;
}