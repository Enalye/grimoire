# Fonctions

Une fonction est un morceau de code qui peut être appelé depuis un autre endroit.
Elles se déclarent comme ceci:
```grimoire
function maFonction() {}
```
Ici, on définit une fonction appelé `maFonction` qui ne prend ni ne retourne de valeur.

Là, on définit une fonction prennant deux entiers et retournant leur somme:
```grimoire
function additionne(int a, int b) (int) {
  return a + b;
}
```
Les types de retour sont toujours mis entre parenthèses après la signature. S’il n’y a pas de type de retour, les parenthèses vides `()` deviennent optionnels.

Sans type de retour, le `return` peut être utilisé sans valeur.
```grimoire
function foo(int n) {
  if(n == 0) {
    print("n est égal à 0");
    return;
  }
  print("n est différent de 0");
}
```

Une fonction peut avoir plusieurs types de retour, le `return` doit retourner les valeurs du bon type et dans le bon ordre.
```grimoire
function foo() (int, string, bool) {
	return 5, "Coucou", false;
}
```