# Tâche

Les tâches `task` sont des fils d’exécution indépendant les unes des autres, on les appelle aussi coroutines.

Elles sont syntaxiquement proches des fonctions à la différence que:
* Une tâche n’a pas de type de retour.
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