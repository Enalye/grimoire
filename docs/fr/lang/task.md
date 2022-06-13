# Tâches

Les tâches sont l’équivalent des coroutines en Grimoire.
Elles sont syntaxiquement proches des fonctions à la différence que:
* Une tâche n’a pas de type de retour et ne peut rien retourner (les canaux permettent ça).
* Une tâche ne sera pas exécutée immédiatement après avoir été appelé et n’interrompera pas l’exécution de la fonction appelante.
* Une tâche peut seulement s’exécuter si les autres tâches sont mortes ou en suspend.

Syntaxe:
```grimoire
task autreTâche() {
  print("3");
  yield
  print("5");
}

event onLoad() {
  print("1");
  doThing();
  print("2");
  yield
  print("4");
}
```
Ici le `onLoad` va afficher *1*, lancer la tâche `autreTâche`, afficher *2*, puis laisser la main à `autreTâche` qui va afficher *3* puis laisser la main à `onLoad` qui affichera *4*. Puis le `onLoad` va mourir permettant à `autreTâche` de poursuivre et d’afficher *5*.

`yield` est une instruction permettant d’interrompre l’exécution d’une tâche pour laisser la main aux autres tâches.
La tâche poursuivra son exécution lorsque toutes les autres tâches se seront exécuté à leur tour.

Une tâche peut également être tuée prématurément à l’aide de `die`.
Veuillez noter qu’à l’intérieur d’une tâche, un `return` se comportera de la même manière qu’un `die`.

`exit` quant à lui, permet de tuer toutes les tâches en cours d’exécution.