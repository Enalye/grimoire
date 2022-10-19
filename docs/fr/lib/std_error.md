# error

## Description

Fonctions pour aider la gestion d’erreur.

## Fonctions

|Fonction|Entrée|Sortie|
|-|-|-|
|[assert](#assert_1)|**bool** *valeur*||
|[assert](#assert_2)|**bool** *valeur*, **pure string** *erreur*||
|[\_setMeta](#setMeta)|**pure string** *valeur*||

---

## Description des fonctions

<a id="assert_1"></a>
- assert(**bool** *valeur*)

Si `valeur` est faux, lance une exception `"AssertError"`.
___

<a id="assert_2"></a>
- assert(**bool** *valeur*, **pure string** *erreur*)

Si `valeur` est faux, lance l’exception `erreur`.
___

<a id="setMeta"></a>
- _setMeta(**pure string** *valeur*)

Fonction interne.
___