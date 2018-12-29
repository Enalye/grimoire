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
    "kill", "yield", "task", "anon_task",
    "pop.i", "pop.f", "pop.s", "pop.n", "pop.a", "pop.o", "pop.u",
    
    "lstore.i", "lstore.f", "lstore.s", "lstore.n", "lstore.a", "lstore.r", "lstore.o", "lstore.u",
    "lstore2.i", "lstore2.f", "lstore2.s", "lstore2.n", "lstore2.a", "lstore2.r", "lstore2.o", "lstore2.u",
    "lload.i", "lload.f", "lload.s", "lload.n", "lload.a", "lload.r", "lload.o", "lload.u",

    "gstore.i", "gstore.f", "gstore.s", "gstore.n", "gstore.a", "gstore.r", "gstore.o", "gstore.u",
    "gstore2.i", "gstore2.f", "gstore2.s", "gstore2.n", "gstore2.a", "gstore2.r", "gstore2.o", "gstore2.u",
    "gload.i", "gload.f", "gload.s", "gload.n", "gload.a", "gload.r", "gload.o", "gload.u",
    
    "const.i", "const.f", "const.b", "const.s",
    
    "gpush.i", "gpush.f", "gpush.s", "gpush.n", "gpush.a", "gpush.o", "gpush.u",
    "gpop.i", "gpop.f", "gpop.s", "gpop.n", "gpop.a", "gpop.o", "gpop.u",

    "eq.i", "eq.f", "eq.s", "eq.a",
    "neq.i", "neq.f", "neq.s", "neq.a",
    "geq.i", "geq.f", "geq.a",
    "leq.i", "leq.f", "leq.a",
    "gt.i", "gt.f", "gt.a",
    "lt.i", "lt.f", "lt.a",

    "and.i", "and.a", "or.i", "or.a", "not.i", "not.a",
    "cat.s", "cat.a",
    "add.i", "add.f", "add.a",
    "sub.i", "sub.f", "sub.a",
    "mul.i", "mul.f", "mul.a",
    "div.i", "div.f", "div.a",
    "rem.i", "rem.f", "rem.a",
    "neg.i", "neg.f", "neg.a",
    "inc.i", "inc.f", "inc.a",
    "dec.i", "dec.f", "dec.a",

    "setup_it",

    "localstack", "call", "anon_call", "prim_call",
    "ret", "unwind", "defer",
    "jmp", "jmp_eq", "jmp_neq",

    "newarray", "length.n", "index.n", "index.r"
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
            (op >= GrOpcode.PopStack_Int && op <= GrOpcode.PopStack_UserData) ||
            (op >= GrOpcode.LocalStore_Int && op <= GrOpcode.LocalLoad_UserData) ||
            (op >= GrOpcode.GlobalStore_Int && op <= GrOpcode.GlobalLoad_UserData) ||
            (op >= GrOpcode.GlobalPush_Int && op <= GrOpcode.GlobalPush_UserData) ||
            (op >= GrOpcode.LocalStack && op <= GrOpcode.Call) ||
            (op == GrOpcode.Build_Array)
            )
            line ~= to!string(grGetInstructionUnsignedValue(opcode));
        else if(op == GrOpcode.PrimitiveCall)
            line ~= grGetPrimitiveDisplayById(grGetInstructionUnsignedValue(opcode));
        else if(op == GrOpcode.Const_Int)
            line ~= to!string(bytecode.iconsts[grGetInstructionUnsignedValue(opcode)]);
        else if(op == GrOpcode.Const_Float)
            line ~= to!string(bytecode.fconsts[grGetInstructionUnsignedValue(opcode)]);
        else if(op == GrOpcode.Const_Bool)
            line ~= (grGetInstructionUnsignedValue(opcode) ? "true" : "false");
        else if(op == GrOpcode.Const_String)
            line ~= "\"" ~ to!string(bytecode.sconsts[grGetInstructionUnsignedValue(opcode)]) ~ "\"";
        else if(op >= GrOpcode.Jump && op <= GrOpcode.JumpNotEqual)
            line ~= to!string(i + grGetInstructionSignedValue(opcode));
        else if(op == GrOpcode.Defer || op == GrOpcode.Try || op == GrOpcode.Catch)
            line ~= to!string(i + grGetInstructionSignedValue(opcode));

        i++;
        result ~= line ~ "\n";
    }
    return result;
}