# Task

Tasks are execution threads independant from one another, they are also called coroutines.

They are syntaxically similar to functions except from a few points:
* A task doesn't declare any return type, but returns its own instance.
* When called, a task will not execute immediately and will not interrupt the caller's flow.
* A task will only be executed if other tasks are killed or suspended.

```grimoire
task myTask() {
  print("Hello !");
}
```
A task can be interrupted by a `yield` or any blocking operation.
```grimoire
task otherTask() {
  print("3");
  yield;
  print("5");
}

event main() {
  print("1");
  otherTask();
  print("2");
  yield;
  yield;
  print("4");
}

// Display -> 1, 2, 3, 4, 5
```

## Instance

A running task has the `instance` type.
`self` returns the instance of the current task.

```grimoire
event app {
    var t: instance = self;
    print(t.isKilled);
}
```

## Terminating a task

`die` is an instruction that terminates the flow of the current task.
When the task end, every declared `defer` block are executed.

```grimoire
event app {
    var t = task {
        die;
    }();

    print(t.isKilled); // false
    yield;
    print(t.isKilled); // true
    die;
    print("This message won't show up");
}
```
> ***Note:***
`die` is placed implicitly at the end of each task.

`exit` terminates the flow of every running task and stops the virtual machine.

```grimoire
event app {
    task {
        loop yield {}
    }();

    exit; // Stops the infinite loop too
}
```

The `kill` primitive can terminate one or several specified task(s).

```grimoire
event app {
    var t: instance = task {
        loop yield {}
    }();

    t.kill();
}
```