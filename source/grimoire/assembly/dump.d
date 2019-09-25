/**
    Bytecode disassembler.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
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

    "field",
    "fstore.i", "fstore.f", "fstore.s", "fstore.o",
    "fload.i", "fload.f", "fload.s", "fload.o",

    "const.i", "const.f", "const.b", "const.s", "meta",
    
    "gpush.i", "gpush.f", "gpush.s", "gpush.o",
    "gpop.i", "gpop.f", "gpop.s", "gpop.o",

    "eq.i", "eq.f", "eq.s",
    "neq.i", "neq.f", "neq.s",
    "geq.i", "geq.f",
    "leq.i", "leq.f",
    "gt.i", "gt.f",
    "lt.i", "lt.f",

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

    "setup_it",

    "localstack", "call", "acall", "vcall", "pcall",
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
];

/// Dump the bytecode's instruction list in a pretty format.
string grDump(GrBytecode bytecode) {
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
        if((op == GrOpcode.Task) ||
            (op >= GrOpcode.LocalStore_Int && op <= GrOpcode.LocalLoad_Object) ||
            (op >= GrOpcode.GlobalStore_Int && op <= GrOpcode.GlobalLoad_Object) ||
            (op >= GrOpcode.GlobalPush_Int && op <= GrOpcode.GlobalPush_Object) ||
            (op >= GrOpcode.LocalStack && op <= GrOpcode.Call) ||
            (op == GrOpcode.New || op == GrOpcode.GetField) ||
            (op >= GrOpcode.Channel_Int && op <= GrOpcode.Channel_Object) ||
            (op >= GrOpcode.Array_Int && op <= GrOpcode.Array_Object)
            )
            line ~= to!string(grGetInstructionUnsignedValue(opcode));
        else if(op >= GrOpcode.FieldStore_Int && op <= GrOpcode.FieldLoad_Object)
            line ~= to!string(grGetInstructionSignedValue(opcode));
        else if(op >= GrOpcode.ShiftStack_Int && op <= GrOpcode.ShiftStack_Object)
            line ~= to!string(grGetInstructionSignedValue(opcode));
        else if(op == GrOpcode.PrimitiveCall)
            line ~= grGetPrimitiveDisplayById(grGetInstructionUnsignedValue(opcode));
        else if(op == GrOpcode.Const_Int)
            line ~= to!string(bytecode.iconsts[grGetInstructionUnsignedValue(opcode)]);
        else if(op == GrOpcode.Const_Float)
            line ~= to!string(bytecode.fconsts[grGetInstructionUnsignedValue(opcode)]);
        else if(op == GrOpcode.Const_Bool)
            line ~= (grGetInstructionUnsignedValue(opcode) ? "true" : "false");
        else if(op == GrOpcode.Const_String || op == GrOpcode.Const_Meta)
            line ~= "\"" ~ to!string(bytecode.sconsts[grGetInstructionUnsignedValue(opcode)]) ~ "\"";
        else if(op >= GrOpcode.Jump && op <= GrOpcode.JumpNotEqual)
            line ~= to!string(i + grGetInstructionSignedValue(opcode));
        else if(op == GrOpcode.Defer || op == GrOpcode.Try || op == GrOpcode.Catch || op == GrOpcode.TryChannel)
            line ~= to!string(i + grGetInstructionSignedValue(opcode));

        i++;
        result ~= line ~ "\n";
    }
    return result;
}