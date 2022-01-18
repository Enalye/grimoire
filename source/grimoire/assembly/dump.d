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
    "rien",
    "erreur",
    "isole",
    "captr",
    "meurs",
    "quitte",
    "suspds",
    "tâche",
    "tâchea",
    "crée",

    "knal.e",
    "knal.r",
    "knal.c",
    "knal.o",
    "env.e",
    "env.r",
    "env.c",
    "env.o",
    "rçoi.e",
    "rçoi.r",
    "rçoi.c",
    "rçoi.o",
    "sélctdb",
    "sélctfn",
    "essaiknal",
    "vérifknal",

    "dcal.e",
    "dcal.r",
    "dcal.c",
    "dcal.o",

    "lenrg.e", "lenrg.r", "lenrg.c", "lenrg.o",
    "lenrg2.e", "lenrg2.r", "lenrg2.c", "lenrg2.o",
    "lchrg.e", "lchrg.r", "lchrg.c", "lchrg.o",

    "genrg.e", "genrg.r", "genrg.c", "genrg.o",
    "genrg2.e", "genrg2.r", "genrg2.c", "genrg2.o",
    "gchrg.e", "gchrg.r", "gchrg.c", "gchrg.o",

    "renrg.e", "renrg.r", "renrg.c", "renrg.o",
    "renrg2.e", "renrg2.r", "renrg2.c", "renrg2.o",

    "cenrg.e", "cenrg.r", "cenrg.c", "cenrg.o",
    "cchrg", "cchrg2",
    "cchrg.e", "cchrg.r", "cchrg.c", "cchrg.o",
    "cchrg2.e", "cchrg2.r", "cchrg2.c", "cchrg2.o",

    "const.e", "const.r", "const.b", "const.c", "méta", "nul",

    "gempil.e", "gempil.r", "gempil.c", "gempil.o",
    "gdpil.e", "gdpil.r", "gdpil.c", "gdpil.o",

    "égl.e", "égl.r", "égl.c",
    "pégl.e", "pégl.r", "pégl.c",
    "pgoé.e", "pgoé.r",
    "ppoé.e", "ppoé.r",
    "pg.e", "pg.r",
    "pp.e", "pp.r",
    "nnul.o",

    "et.e", "ou.e", "pas.e",
    "cncat.c",
    "plus.e", "plus.r",
    "moins.e", "moins.r",
    "mul.e", "mul.r",
    "div.e", "div.r",
    "reste.e", "reste.r",
    "nég.e", "nég.r",
    "incr.e", "incr.r",
    "décr.e", "décr.r",

    "copie.e", "copie.r", "copie.c", "copie.o",
    "prmut.e", "prmut.r", "prmut.c", "prmut.o",

    "prépitér",

    "loc.e", "loc.r", "loc.c", "loc.o",
    "appel", "appela", "appelp",
    "retrn", "déroule", "reporte",
    "saut", "saut0", "sautp0",

    "liste.e", "liste.r", "liste.c", "liste.o",
    "long.e", "long.r", "long.c", "long.o",
    "indx.e", "indx.r", "indx.c", "indx.o",
    "indx2.e", "indx2.r", "indx2.c", "indx2.o",
    "indx3.e", "indx3.r", "indx3.c", "indx3.o",

    "cncat.ne", "cncat.nf", "cncat.ns", "cncat.no",
    "ajoutfn.e", "ajoutfn.r", "ajoutfn.c", "ajoutfn.o",
    "ajoutdb.e", "ajoutdb.r", "ajoutdb.c", "ajoutdb.o",

    "égl.ne", "égl.nf", "égl.ns",
    "pégl.ne", "pégl.nf", "pégl.ns",

    "profldb", "proflfn"
];

/// Dump the bytecode's instruction liste in a pretty format.
string grDump(GrBytecode bytecode) {
    /*writeln("\n----- VM DUMP ------");
    writeln("iconsts: ", bytecode.iconsts);
    writeln("rconsts: ", bytecode.rconsts);
    writeln("sconsts: ", bytecode.sconsts);
    writeln("\nOpcodes:");*/

    string result;
    uint i;
    foreach(uint opcode; bytecode.opcodes) {
        GrOpcode op = cast(GrOpcode)grGetInstructionOpcode(opcode);

        string line = leftJustify("[" ~ to!string(i) ~ "]", 10) ~ leftJustify(instructions[op], 15);
        if((op == GrOpcode.task) ||
            (op >= GrOpcode.localStore_int && op <= GrOpcode.localLoad_object) ||
            (op >= GrOpcode.globalStore_int && op <= GrOpcode.globalLoad_object) ||
            (op >= GrOpcode.globalPush_int && op <= GrOpcode.globalPush_object) ||
            (op >= GrOpcode.localStack_int && op <= GrOpcode.call) ||
            (op == GrOpcode.new_) ||
            (op >= GrOpcode.fieldLoad && op <= GrOpcode.fieldLoad2_object) ||
            (op >= GrOpcode.channel_int && op <= GrOpcode.channel_object) ||
            (op >= GrOpcode.list_int && op <= GrOpcode.list_object)
            )
            line ~= to!string(grGetInstructionUnsignedValue(opcode));
        else if(op >= GrOpcode.fieldStore_int && op <= GrOpcode.fieldStore_object)
            line ~= to!string(grGetInstructionSignedValue(opcode));
        else if(op >= GrOpcode.shiftStack_int && op <= GrOpcode.shiftStack_object)
            line ~= to!string(grGetInstructionSignedValue(opcode));
        else if(op == GrOpcode.primitiveCall)
            line ~= to!string(grGetInstructionUnsignedValue(opcode));
        else if(op == GrOpcode.const_int)
            line ~= to!string(bytecode.iconsts[grGetInstructionUnsignedValue(opcode)]);
        else if(op == GrOpcode.const_real)
            line ~= to!string(bytecode.rconsts[grGetInstructionUnsignedValue(opcode)]);
        else if(op == GrOpcode.const_bool)
            line ~= (grGetInstructionUnsignedValue(opcode) ? "vrai" : "faux");
        else if(op == GrOpcode.const_string || op == GrOpcode.const_meta || op == GrOpcode.debugProfileBegin)
            line ~= "\"" ~ to!string(bytecode.sconsts[grGetInstructionUnsignedValue(opcode)]) ~ "\"";
        else if(op >= GrOpcode.jump && op <= GrOpcode.jumpNotEqual)
            line ~= to!string(i + grGetInstructionSignedValue(opcode));
        else if(op == GrOpcode.defer || op == GrOpcode.isolate || op == GrOpcode.capture || op == GrOpcode.tryChannel)
            line ~= to!string(i + grGetInstructionSignedValue(opcode));

        i++;
        result ~= line ~ "\n";
    }
    return result;
}