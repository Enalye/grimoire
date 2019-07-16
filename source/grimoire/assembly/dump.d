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
    "kill", "yield", "task", "anon_task", "new",

    "chan.i", "chan.f", "chan.s", "chan.v", "chan.o",
    "snd.i", "snd.f", "snd.s", "snd.v", "snd.o",
    "rcv.i", "rcv.f", "rcv.s", "rcv.v", "rcv.o",
    "select", "chan_try", "chan_check",

    "shift.i", "shift.f", "shift.s", "shift.v", "shift.o",
    
    "lstore.i", "lstore.f", "lstore.s", "lstore.v", "lstore.r", "lstore.o",
    "lstore2.i", "lstore2.f", "lstore2.s", "lstore2.v", "lstore2.r", "lstore2.o",
    "lload.i", "lload.f", "lload.s", "lload.v", "lload.r", "lload.o",

    "gstore.i", "gstore.f", "gstore.s", "gstore.v", "gstore.r", "gstore.o",
    "gstore2.i", "gstore2.f", "gstore2.s", "gstore2.v", "gstore2.r", "gstore2.o",
    "gload.i", "gload.f", "gload.s", "gload.v", "gload.r", "gload.o",
    
    "field",
    "fstore.i", "fstore.f", "fstore.s", "fstore.v", "fstore.r", "fstore.o",
    "fload.i", "fload.f", "fload.s", "fload.v", "fload.r", "fload.o",

    "const.i", "const.f", "const.b", "const.s", "meta",
    
    "gpush.i", "gpush.f", "gpush.s", "gpush.v", "gpush.o",
    "gpop.i", "gpop.f", "gpop.s", "gpop.v", "gpop.o",

    "eq.i", "eq.f", "eq.s", "eq.v",
    "neq.i", "neq.f", "neq.s", "neq.v",
    "geq.i", "geq.f", "geq.v",
    "leq.i", "leq.f", "leq.v",
    "gt.i", "gt.f", "gt.v",
    "lt.i", "lt.f", "lt.v",

    "and.i", "and.v", "or.i", "or.v", "not.i", "not.v",
    "cat.s", "cat.v",
    "add.i", "add.f", "add.v",
    "sub.i", "sub.f", "sub.v",
    "mul.i", "mul.f", "mul.v",
    "div.i", "div.f", "div.v",
    "rem.i", "rem.f", "rem.v",
    "neg.i", "neg.f", "neg.v",
    "inc.i", "inc.f", "inc.v",
    "dec.i", "dec.f", "dec.v",

    "setup_it",

    "localstack", "call", "acall", "vcall", "pcall",
    "ret", "unwind", "defer",
    "jmp", "jmp_eq", "jmp_neq",

    "newarray", "length.n", "index.n", "index.v",
    "copy.n", "copy.v"
];

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
            (op == GrOpcode.Build_Array || op == GrOpcode.New || op == GrOpcode.GetField) ||
            (op >= GrOpcode.Channel_Int && op <= GrOpcode.Channel_Object)
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
        else if(op == GrOpcode.Const_String || op == GrOpcode.Const_Meta || op == GrOpcode.VariantCall)
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