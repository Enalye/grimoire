import std.stdio: writeln;
import std.datetime;

import grimoire;

void main() {
	try {
		loadStandardLibrary();
        auto startTime = MonoTime.currTime();
        auto bytecode = compileFile("test.grimoire");
        auto compilationTime = MonoTime.currTime() - startTime;

        dumpBytecode(bytecode);
        GrimoireVM vm = new GrimoireVM;
        vm.load(bytecode);
        vm.spawn();
        
        startTime = MonoTime.currTime();
        vm.process();
        auto executionTime = MonoTime.currTime() - startTime;

        writeln("Compilation took: \t", compilationTime.total!"usecs", " us");
        writeln("Execution took: \t", executionTime.total!"usecs", " us");
	}
	catch(Exception e) {
		writeln(e.msg);
	}
}
