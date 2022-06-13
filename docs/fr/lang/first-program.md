
# Premier programme

Commençons avec le traditionnel « Hello World »:
```grimoire
event onLoad() {
  print("Hello World!");
}
```
Ce code est composé du mot-clé `event` qui permet la déclaration d’une tâche pouvant être appelé depuis D. Ici, on la nomme `onLoad`.

Les parenthèses suivantes permette de définir la *signature* de la fonction, comme on ne veut pas de paramètres, on laisse ces parenthèses vides.

Ensuite une paire d’accolades entourent le `print`, elles détourent l’ensemble du code associé à la fonction `onLoad` qui sera exécuté à l’appel de la fonction.

La ligne `print("Hello World!");` forme une expression se terminant toujours par un point-virgule.
On passe la chaîne de caractère « Hello World! » à la primitive `print` qui se chargera de l’afficher.