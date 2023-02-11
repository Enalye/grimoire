# Task

Tasks are execution threads independant from one another, they are also called coroutines.

They are syntaxically similar to functions except from a few points:
* A task have no return type.
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
  yield
  print("5");
}

event main() {
  print("1");
  otherTask();
  print("2");
  yield
  yield
  print("4");
}

// Display -> 1, 2, 3, 4, 5
```