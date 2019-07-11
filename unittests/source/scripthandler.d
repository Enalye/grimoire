module scripthandler;

import std.stdio, core.thread;
import grimoire;

final class ScriptHandler {
    private final class TimeoutThread: Thread {
        private {
            __gshared ScriptHandler _script;
        }
        shared bool isRunning = true;
        shared bool isTimedout;

        this(ScriptHandler script) {
            _script = script;
            super(&run);
        }

        void run() {
            try {
                const auto startTime = MonoTime.currTime();
                while(isRunning) {
                    const auto currentCycle = _script._cycle;
                    sleep(dur!("msecs")(100));
                    if(currentCycle == _script._cycle && _script._isLoaded) {
                        isTimedout = true;
                        isRunning = false;
                        _script.engine.isRunning = false;
                    }
                    const auto deltaTime = MonoTime.currTime() - startTime;
                    if(deltaTime > dur!"msecs"(1000)) {
                        isTimedout = true;
                        isRunning = false;
                        _script.engine.isRunning = false;
                    }
                }
            }
            catch(Exception e) {
                writeln("Script timeout error: ", e.msg);
            }
        }
    }

    private {
        shared int _cycle;
        shared bool _isLoaded = false;
        TimeoutThread _timeout;
    }

    GrEngine engine;

    @property {
        bool isRunning() { return engine.hasCoroutines && !engine.isPanicking && engine.isRunning; }
        bool isTimedout() { return _timeout.isTimedout; }
    }

    void cleanup() {
        engine.isRunning = false;
        _isLoaded = false;
        if(_timeout) {
            _timeout.isRunning = false;
            _timeout = null;
        }
    }

    void load(string name) {
        auto bytecode = grCompileFile(name);
        engine = new GrEngine;
        engine.load(bytecode);
        engine.spawn();
        _timeout = new TimeoutThread(this);
        _timeout.start();
    }

    void run() {
        _isLoaded = true;
        if(engine.hasCoroutines)
            engine.process();
        _cycle = _cycle + 1;
        if(!engine.hasCoroutines || engine.isPanicking)
            _timeout.isRunning = false;
    }
}