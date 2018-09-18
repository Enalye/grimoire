/**
    Bytecode disassembler.

    Copyright: (c) Enalye 2018
    License: Zlib
    Authors: Enalye
*/

module assembly.dump;

import std.conv: to;
import std.string: leftJustify;

import assembly.bytecode;

private string[] instructions = [
    "kill", "yield", "task", "anon_task",
    "pop.i", "pop.f", "pop.s", "pop.n", "pop.a", "pop.o",
    "lstore.i", "lstore.f", "lstore.s", "lstore.n", "lstore.a", "lstore.r", "lstore.o",
    "lstore2.i", "lstore2.f", "lstore2.s", "lstore2.n", "lstore2.a", "lstore2.r", "lstore2.o",
    "lload.i", "lload.f", "lload.s", "lload.n", "lload.a", "lload.r", "lload.o",
    "const.i", "const.f", "const.b", "const.s",
    "gpush.i", "gpush.f", "gpush.s", "gpush.n", "gpush.a", "gpush.o",
    "gpop.i", "gpop.f", "gpop.s", "gpop.n", "gpop.a", "gpop.o",

    "conv.ba", "conv.ia", "conv.fa", "conv.sa", "conv.na",
    "conv.ab", "conv.ai", "conv.af", "conv.as", "conv.an",

    "eq.i", "eq.f", "eq.s", "eq.a",
    "neq.i", "neq.f", "neq.s", "neq.a",
    "geq.i", "geq.f", "geq.a",
    "ile", "fle", "leq.a",
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

    "localstack", "call", "anon_call", "prim_call", "ret",
    "jmp", "jmp_eq", "jmp_neq",

    "newarray", "length.n", "index.n", "index.r"
];

string grBytecode_dump(GrBytecode bytecode) {
    /*writeln("\n----- VM DUMP ------");
    writeln("iconsts: ", bytecode.iconsts);
    writeln("fconsts: ", bytecode.fconsts);
    writeln("sconsts: ", bytecode.sconsts);
    writeln("\nOpcodes:");*/

    string result;
    uint i;
    foreach(uint opcode; bytecode.opcodes) {
        GrOpcode op = cast(GrOpcode)grBytecode_getOpcode(opcode);

        string line = leftJustify("[" ~ to!string(i) ~ "]", 10) ~ leftJustify(instructions[op], 15);
        if((op == GrOpcode.Task) ||
            (op >= GrOpcode.PopStack_Int && op <= GrOpcode.PopStack_Object) ||
            (op >= GrOpcode.LocalStore_Int && op <= GrOpcode.LocalLoad_Object) ||
            (op >= GrOpcode.GlobalPush_Int && op <= GrOpcode.GlobalPush_Object) ||
            (op >= GrOpcode.LocalStack && op <= GrOpcode.PrimitiveCall) ||
            (op == GrOpcode.ArrayBuild)
            )
            line ~= to!string(grBytecode_getUnsignedValue(opcode));
        else if(op == GrOpcode.Const_Int)
            line ~= to!string(bytecode.iconsts[grBytecode_getUnsignedValue(opcode)]);
        else if(op == GrOpcode.Const_Float)
            line ~= to!string(bytecode.fconsts[grBytecode_getUnsignedValue(opcode)]);
        else if(op == GrOpcode.Const_Bool)
            line ~= (bytecode.iconsts[grBytecode_getUnsignedValue(opcode)] ? "true" : "false");
        else if(op == GrOpcode.Const_String)
            line ~= "\"" ~ to!string(bytecode.sconsts[grBytecode_getUnsignedValue(opcode)]) ~ "\"";
        if(op >= GrOpcode.Jump && op <= GrOpcode.JumpNotEqual)
            line ~= to!string(i + grBytecode_getSignedValue(opcode));
        
        i++;
        result ~= line ~ "\n";
    }
    return result;
}