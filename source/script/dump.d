/**
Grimoire
Copyright (c) 2017 Enalye

This software is provided 'as-is', without any express or implied warranty.
In no event will the authors be held liable for any damages arising
from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute
it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented;
	   you must not claim that you wrote the original software.
	   If you use this software in a product, an acknowledgment
	   in the product documentation would be appreciated but
	   is not required.

	2. Altered source versions must be plainly marked as such,
	   and must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source distribution.
*/

module script.dump;

import std.stdio;
import std.conv: to;
import std.string: leftJustify;

import script.bytecode;

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

void dumpBytecode(Bytecode bytecode) {
    /*writeln("\n----- VM DUMP ------");
    writeln("iconsts: ", bytecode.iconsts);
    writeln("fconsts: ", bytecode.fconsts);
    writeln("sconsts: ", bytecode.sconsts);
    writeln("\nOpcodes:");*/

    uint i;
    foreach(uint opcode; bytecode.opcodes) {
        Opcode op = cast(Opcode)getInstruction(opcode);

        string line = leftJustify("[" ~ to!string(i) ~ "]", 10) ~ leftJustify(instructions[op], 15);
        if((op == Opcode.Task) ||
            (op >= Opcode.PopStack_Int && op <= Opcode.PopStack_Object) ||
            (op >= Opcode.LocalStore_Int && op <= Opcode.LocalLoad_Object) ||
            (op >= Opcode.GlobalPush_Int && op <= Opcode.GlobalPush_Object) ||
            (op >= Opcode.LocalStack && op <= Opcode.PrimitiveCall) ||
            (op == Opcode.ArrayBuild)
            )
            line ~= to!string(getValue(opcode));
        else if(op == Opcode.Const_Int)
            line ~= to!string(bytecode.iconsts[getValue(opcode)]);
        else if(op == Opcode.Const_Float)
            line ~= to!string(bytecode.fconsts[getValue(opcode)]);
        else if(op == Opcode.Const_Bool)
            line ~= (bytecode.iconsts[getValue(opcode)] ? "true" : "false");
        else if(op == Opcode.Const_String)
            line ~= "\"" ~ to!string(bytecode.sconsts[getValue(opcode)]) ~ "\"";
        if(op >= Opcode.Jump && op <= Opcode.JumpNotEqual)
            line ~= to!string(i + getSignedValue(opcode));
        writeln(line);
        i++;
    }
}