# Const & Pure

Grimoire has two type of modifiers `const` and `pure`.

`const` prevent a variable from being assigned.
```grimoire
const a: int = 5;
a = 6; // Error
a ++; // Error
```
However, it does not prevent its content from being modified.
```grimoire
class Character {
    var name: string;
}

event main() {
    const character = @Character {
        name = "Nick";
    };

    character = @Character {
        name = "Will";
    }; // Error

    character.name = "Turing"; // Allowed
}
```

On the other hand, `pure` makes the type's content unchangeable.
```grimoire
class Character {
    var name: string;
}

event main() {
    var character: pure Character = @Character {
        name = "Nick";
    };

    character = @Character {
        name = "Will";
    }; // Allowed

    character.name = "Turing"; // Error
}
```

`const` and `pure` can be combined to make the variable immutable.
```grimoire
class Character {
    var name: string;
}

event main() {
    const character: pure Character = @Character {
        name = "Nick";
    };

    character = @Character {
        name = "Will";
    }; // Error

    character.name = "Turing"; // Error
}
```