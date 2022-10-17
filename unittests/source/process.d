module process;

import std.stdio, std.file, core.thread, std.path;
import std.conv : to;
import std.datetime;
import grimoire;
import tester;

void testAll(GrLocale locale) {
    auto files = dirEntries("", "{*.gr}", SpanMode.depth);
    const auto startTime = MonoTime.currTime();
    uint totalSuites, successSuites, failedSuites;
    uint totalTests, successTests, failedTests;

    writeln("\033[0;90mDébut de la batterie de tests");

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
            report ~= "\033[1;102m SUCCÈS \033[0;90m ";
            successSuites++;
        }
        else if (!testSerie.hasCompiled) {
            report ~= "\033[1;101m ERREUR \033[0;90m ";
            failedSuites++;
        }
        else {
            report ~= "\033[1;101m ÉCHEC \033[0;90m ";
            failedSuites++;
        }
        report ~= fileDir ~ dirSeparator ~ "\033[0;1m" ~ fileName ~ "\033[0m";

        foreach (ref subTest; testSerie.subTests) {
            report ~= "\n";
            totalTests++;
            final switch (subTest.type) with (UnitTester.TestSerie.SubTest.Type) {
            case success:
                report ~= "    \033[1;92m✔ \033[0;90m" ~ subTest.name;
                report ~= " (" ~ to!string(subTest.time.total!"msecs") ~ "ms)";
                successTests++;
                break;
            case failure:
                report ~= "    \033[1;91m✘ \033[0;90m" ~ subTest.name;
                report ~= " (" ~ to!string(subTest.time.total!"msecs") ~ "ms)";
                failedTests++;
                break;
            case timeout:
                report ~= "    \033[1;93m✘ \033[0;90m" ~ subTest.name;
                report ~= " (\033[1;93mtemps écoulé\033[0m)";
                failedTests++;
                break;
            }
        }
        report ~= "\n";
        if (!testSerie.hasCompiled) {
            report ~= "\n" ~ testSerie.comment ~ "\n\n";
        }
        else {
            foreach (ref subTest; testSerie.subTests) {
                if (subTest.comment) {
                    report ~= "\n    \033[1;91m• " ~ subTest.name ~ " > " ~ subTest.comment ~ "\n";
                }
            }
        }

        report ~= "\033[0m";
        write(report);
        handler.cleanup();
    }
    auto totalTime = MonoTime.currTime() - startTime;

    string result = "\033[0;1mSéries: ";
    if (successSuites) {
        result ~= "\033[1;92m" ~ to!string(successSuites) ~ " " ~ (successSuites > 1 ?
                "réussis" : "réussi") ~ "\033[0;90m";
        if (failedSuites) {
            result ~= ", ";
        }
    }
    if (failedSuites) {
        result ~= "\033[1;91m" ~ to!string(failedSuites) ~ " " ~ (failedSuites > 1 ?
                "échoués" : "échoué") ~ "\033[0;90m";
    }
    result ~= ", " ~ to!string(totalSuites) ~ " en tout\n";

    result ~= "\033[0;1mTests:  ";
    if (successTests) {
        result ~= "\033[1;92m" ~ to!string(successTests) ~ " " ~ (successTests > 1 ?
                "réussis" : "réussi") ~ "\033[0;90m";
        if (failedTests) {
            result ~= ", ";
        }
    }
    if (failedTests) {
        result ~= "\033[1;91m" ~ to!string(failedTests) ~ " " ~ (failedTests > 1 ?
                "échoués" : "échoué") ~ "\033[0;90m";
    }
    result ~= ", " ~ to!string(totalTests) ~ " en tout\n";
    result ~= "\033[0;1mDurée:\033[0;90m  " ~ to!string(totalTime.total!"msecs" / 1_000f) ~ "s";
    writeln(result);
    writeln("\033[0;90mFin des tests\033[0;0m");
}
