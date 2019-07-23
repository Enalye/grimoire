## [Next: Anonymous function/task](anon.md)
## [Prev: Creating a function](function.md)
## [Main Page](index.md)

# Task

Task are Grimoire's implementation of coroutines. They are syntaxically similar to function except from a few points:
* A task have no return type and can't return anything.
* When called, a task will not execute immediately and will not interrupt the caller's flow.
* A task will only be executed if other tasks are killed or on yield.

Syntax:
```cpp
task doThing() {
  print("3");
  yield
  print("5");
}

main {
  print("1");
  doThing();
  print("2");
  yield
  print("4");
}
```
Here, the main will print 1, spawn the doThing task, print 2 then yield to the doThing task which will print 3 then yield again to the main which will print 4. Then the main will die so the doThing task will resume and print 5.

To interrupt the flow of execution of the task and let other task continue, you can use the keyword **yield**.
The task will run again after all other tasks have run once.

You can also delete the task with the keyword **kill**. Also be aware that inside the scope of a task, the keyword **return** will behave the same as **kill**.

Note: The main is a special case of a task.



# Navigation

## [Next: Anonymous function/task](anon.md)
## [Prev: Creating a function](function.md)
## [Main Page](index.md)