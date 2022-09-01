/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module tester;

import std.stdio, std.file, core.thread;
import std.conv : to;
import std.datetime;
import grimoire;

final class UnitTester {
    private final class TimeoutThread : Thread {
        private {
            __gshared UnitTester _tester;
        }
        shared bool isRunning = true;
        shared bool isTimedout;

        this(UnitTester tester) {
            _tester = tester;
            super(&run);
        }

        void run() {
            try {
                const auto startTime = MonoTime.currTime();
                while (isRunning) {
                    const auto currentCycle = _tester._cycle;
                    sleep(dur!("msecs")(100));
                    if (currentCycle == _tester._cycle && _tester._isLoaded) {
                        isTimedout = true;
                        isRunning = false;
                        if (_tester._engine)
                            _tester._engine.isRunning = false;
                    }
                    const auto deltaTime = MonoTime.currTime() - startTime;
                    if (deltaTime > dur!"msecs"(1000)) {
                        isTimedout = true;
                        isRunning = false;
                        if (_tester._engine)
                            _tester._engine.isRunning = false;
                    }
                }
            }
            catch (Exception e) {
                writeln("Script timeout error: ", e.msg);
            }
        }
    }

    struct TestSerie {
        bool hasCompiled, hasPassed;
        string comment;
        SubTest[] subTests;

        struct SubTest {
            enum Type {
                success,
                failure,
                timeout
            }

            Type type;
            string name, comment;
            Duration time;
        }
    }

    private {
        shared int _cycle;
        shared bool _isLoaded = false;
        TimeoutThread _timeout;

        GrLibrary _stdlib, _testlib;
        GrCompiler _compiler;
        GrLocale _locale;
        GrEngine _engine;
    }

    this(GrLocale locale) {
        _locale = locale;

        _stdlib = grLoadStdLibrary();
        _compiler = new GrCompiler;
        _compiler.addLibrary(_stdlib);
    }

    TestSerie run(string fileName) {
        TestSerie testSerie;

        GrBytecode bytecode = _compiler.compileFile(fileName, GrOption.symbols, _locale);
        if (!bytecode) {
            testSerie.comment = _compiler.getError().prettify(GrLocale.fr_FR);
            return testSerie;
        }
        testSerie.hasCompiled = true;
        testSerie.hasPassed = true;

        string[] events = bytecode.getEvents();

        foreach (string event; events) {
            auto composite = grUnmangleComposite(event);
            if (composite.signature.length)
                continue;

            _engine = new GrEngine;
            _engine.addLibrary(_stdlib);
            _engine.load(bytecode);

            TestSerie.SubTest subTest;
            subTest.name = composite.name;

            _engine.callEvent(event);

            _timeout = new TimeoutThread(this);
            _timeout.start();
            _isLoaded = true;

            const auto startTime = MonoTime.currTime();
            while (_engine.hasTasks && !_timeout.isTimedout) {
                _engine.process();
                _cycle = _cycle + 1;
            }
            subTest.time = MonoTime.currTime() - startTime;

            _isLoaded = false;
            _timeout.isRunning = false;

            if (_timeout.isTimedout) {
                testSerie.hasPassed = false;
                subTest.type = TestSerie.SubTest.Type.timeout;
            }
            else if (_engine.isPanicking) {
                testSerie.hasPassed = false;
                subTest.type = TestSerie.SubTest.Type.failure;
                subTest.comment = "\033[1;91m" ~ to!string(_engine.panicMessage) ~ "\033[0;90m\n";
                foreach (trace; _engine.stackTraces) {
                    subTest.comment ~= "        [" ~ to!string(
                        trace.pc) ~ "] dans " ~ trace.name ~ " à " ~ trace.file ~ "(" ~ to!string(
                        trace.line) ~ "," ~ to!string(trace.column) ~ ")\n";
                }
            }
            testSerie.subTests ~= subTest;
        }
        return testSerie;
    }

    void cleanup() {
        _isLoaded = false;
        if (_timeout) {
            _timeout.isRunning = false;
            _timeout = null;
        }
    }
}
