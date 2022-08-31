/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module tester;

import std.stdio, std.file, core.thread, std.path;
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

        _engine = new GrEngine;
        _engine.addLibrary(_stdlib);
        _engine.load(bytecode);
        string[] events = _engine.getEvents();

        foreach (string event; events) {
            auto composite = grUnmangleComposite(event);
            if (composite.signature.length)
                continue;

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
                subTest.comment = "panic: " ~ to!string(_engine.panicMessage) ~ "\n";
                foreach (trace; _engine.stackTraces) {
                    subTest.comment ~= "[" ~ to!string(
                        trace.pc) ~ "] in " ~ trace.name ~ " at " ~ trace.file ~ "(" ~ to!string(
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

void testAll(GrLocale locale) {
    auto files = dirEntries("", "{*.gr}", SpanMode.depth);
    const auto startTime = MonoTime.currTime();
    uint totalSuites, successSuites, failedSuites;
    uint totalTests, successTests, failedTests;

    foreach (file; files) {
        UnitTester handler = new UnitTester(locale);
        if (!file.isFile)
            continue;
        totalSuites++;
        string report;
        UnitTester.TestSerie testSerie = handler.run(file);

        string fileDir = dirName(file);
        string fileName = baseName(file);
        if (testSerie.hasPassed) {
            report ~= "\033[1;102m SUCCÈS \033[0m ";
            successTests++;
        }
        else if (!testSerie.hasCompiled) {
            report ~= "\033[1;101m ERREUR \033[0m ";
            failedSuites++;
        }
        else {
            report ~= "\033[1;101m ÉCHEC \033[0m ";
            failedSuites++;
        }
        report ~= fileDir ~ dirSeparator ~ "\033[1m" ~ fileName ~ "\033[0m";

        foreach (ref subTest; testSerie.subTests) {
            report ~= "\n";
            totalTests++;
            final switch (subTest.type) with (UnitTester.TestSerie.SubTest.Type) {
            case success:
                report ~= "    \033[1;32m✔ \033[0m" ~ subTest.name;
                successTests++;
                break;
            case failure:
                report ~= "    \033[1;31m✘ \033[0m" ~ subTest.name;
                failedTests++;
                break;
            case timeout:
                report ~= "    \033[1;33m✘ \033[0m" ~ subTest.name;
                failedTests++;
                break;
            }
            report ~= " (" ~ to!string(subTest.time.total!"msecs") ~ "ms)";
        }
        if (!testSerie.hasCompiled) {
            report ~= "\n" ~ testSerie.comment;
        }

        report ~= "\033[0m";
        writeln(report);
        handler.cleanup();
    }

    auto totalTime = MonoTime.currTime() - startTime;

    string result = "\033[1mSéries: \t";
    if (successSuites) {
        result ~= "\033[1;32m" ~ to!string(successSuites) ~ " réussis\033[1m";
        if (failedSuites) {
            result ~= ", ";
        }
    }
    if (failedSuites) {
        result ~= "\033[1;31m" ~ to!string(failedSuites) ~ " échecs\033[0;1m";
    }
    result ~= " sur " ~ to!string(totalSuites) ~ "\n";
    

    result ~= "\033[1mTests:  \t";
    if (successTests) {
        result ~= "\033[1;32m" ~ to!string(successTests) ~ " réussis\033[1m";
        if (failedTests) {
            result ~= ", ";
        }
    }
    if (failedTests) {
        result ~= "\033[1;31m" ~ to!string(failedTests) ~ " échecs\033[0;1m";
    }
    result ~= " sur " ~ to!string(totalTests) ~ "\n";

    result ~= "Durée:  \t" ~ to!string(totalTime.total!"msecs" / 1_000f) ~ "s\n";
    result ~= "\033[0m";

    writeln(result);
}
