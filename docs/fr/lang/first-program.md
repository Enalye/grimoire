
# First Program

Starting with the traditionnal "Hello World" :
```grimoire
event onLoad() {
  print("Hello World!");
}
```
The code is composed of the keyword **event**, which allow use to declare a task that can be called from D. Here we name that event `main`.

Then we have a left curly brace `{` with a right curly brace `}` some lines after.
Those curly braces delimit the scope of the statement (here, the **main**).

Everything inside those curly braces (called a **block**) will be executed when `main` is run.

The whole `print("Hello World!");` form a single expression terminated by a semicolon.
We pass the "Hello World!" string to the **print** primitive which will then display: `Hello World!`.