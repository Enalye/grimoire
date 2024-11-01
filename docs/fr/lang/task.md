# Tâche

Les tâches `task` sont des fils d’exécution indépendant les unes des autres, on les appelle aussi coroutines.

Elles sont syntaxiquement proches des fonctions à la différence que:
* Une tâche ne déclare pas de type de retour, mais retourne son instance.
* Une tâche ne sera pas exécutée immédiatement après avoir été appelé et n’interrompera pas l’exécution de la fonction appelante.
* Une tâche peut seulement s’exécuter si les autres tâches sont mortes ou en suspend.

```grimoire
task maTâche() {
  print("Bonjour !");
}
```
Une tâche peut être interrompue par un `yield` ou autre opération bloquante.
```grimoire
task autreTâche() {
  print("3");
  yield;
  print("5");
}

event main() {
  print("1");
  autreTâche();
  print("2");
  yield;
  yield;
  print("4");
}

// Affiche -> 1, 2, 3, 4, 5
```

## Instance

Une tâche exécuté est de type `instance`.
`self` renvoie l’instance de la tâche en cours.

```grimoire
event app {
    var t: instance = self;
    print(t.isKilled);
}
```

## Terminer une tâche

`die` est une instruction qui termine l’exécution de la tâche actuelle.
À l’arrêt de la tâche, tous les blocs `defer` déclarés s’exécutent.

```grimoire
event app {
    var t = task {
        die;
    }();

    print(t.isKilled); // false
    yield;
    print(t.isKilled); // true
    die;
    print("Ce message ne s’affichera pas");
}
```
> ***Note:***
`die` est implicitement placé à la fin de chaque tâche.

`exit` termine l’exécution de toutes les tâches et arrête la machine virtuelle.

```grimoire
event app {
    task {
        loop yield {}
    }();

    exit; // Termine également la boucle infinie
}
```

La primitive `kill` permet de terminer une ou plusieurs tâche(s) désignée(s).

```grimoire
event app {
    var t: instance = task {
        loop yield {}
    }();

    t.kill();
}
```