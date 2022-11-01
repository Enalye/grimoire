# std.string

Type de base.
## Description
Type pouvant contenir des caractères UTF-8.
## Natifs
### StringIterator
Itère sur les caractères d’une chaîne.
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[clear](#func_0)|**string** *str*||
|[contains](#func_1)|**pure string** *str*, **pure string** *valeur*|**bool**|
|[copy](#func_2)|**pure string** *str*|**string**|
|[each](#func_3)|**string** *chaîne*|**StringIterator**|
|[first](#func_4)|**pure string** *str*|**string?**|
|[indexOf](#func_5)|**pure string** *str*, **pure string** *valeur*|**int?**|
|[insert](#func_6)|**string** *liste*, **int** *index*, **pure string** *valeur*||
|[isEmpty](#func_7)|**pure string** *str*|**bool**|
|[last](#func_8)|**pure string** *str*|**string?**|
|[lastIndexOf](#func_9)|**pure string** *str*, **pure string** *valeur*|**int?**|
|[next](#func_10)|**StringIterator** *itérateur*|**string?**|
|[pop](#func_11)|**string** *str*|**string?**|
|[pop](#func_12)|**string** *str*, **int** *quantité*|**string**|
|[push](#func_13)|**string** *str*, **string** *valeur*||
|[remove](#func_14)|**string** *str*, **int** *index*||
|[remove](#func_15)|**string** *str*, **int** *indexDébut*, **int** *indexFin*||
|[reverse](#func_16)|**pure string** *str*|**string**|
|[shift](#func_17)|**string** *str*|**string?**|
|[shift](#func_18)|**string** *str*, **int** *quantité*|**string**|
|[size](#func_19)|**pure string** *str*|**int**|
|[slice](#func_20)|**pure string** *str*, **int** *indexDébut*, **int** *indexFin*|**string**|
|[unshift](#func_21)|**string** *str*, **string** *valeur*||


***
## Description des fonctions

<a id="func_0"></a>
> clear (**string** *str*)

Vide la `str`.

<a id="func_1"></a>
> contains (**pure string** *str*, **pure string** *valeur*) (**bool**)

Renvoie `true` si `valeur` existe dans `str`.

<a id="func_2"></a>
> copy (**pure string** *str*) (**string**)

Retourne une copie d’`str`.

<a id="func_3"></a>
> each (**string** *chaîne*) (**StringIterator**)

Retourne un itérateur qui parcours chaque caractère de la chaîne.

<a id="func_4"></a>
> first (**pure string** *str*) (**string?**)

Retourne le premier élément d’`str`.
S’il n’existe pas, retourne `null(T)`.

<a id="func_5"></a>
> indexOf (**pure string** *str*, **pure string** *valeur*) (**int?**)

Retourne la première occurence de `valeur` dans `str` à partir d’`index`.
Si `valeur  n’existe pas, `null(int)` est renvoyé.
Si `index` est négatif, l’`index` est calculé à partir de la fin d’`str`.

<a id="func_6"></a>
> insert (**string** *liste*, **int** *index*, **pure string** *valeur*)

Insère `valeur` dans la `str` à l’`index` spécifié.
Si `index` dépasse la taille d’`str`, `valeur` est ajouté en fin d’`str`.
Si `index` est négatif, l’`index` est calculé à partir de la fin d’`str`.

<a id="func_7"></a>
> isEmpty (**pure string** *str*) (**bool**)

Renvoie `true` si la `str` ne contient rien.

<a id="func_8"></a>
> last (**pure string** *str*) (**string?**)

Returne le dernier élément d’`str`.
S’il n’existe pas, retourne `null(T)`.

<a id="func_9"></a>
> lastIndexOf (**pure string** *str*, **pure string** *valeur*) (**int?**)

Retourne la dernière occurence de `valeur` dans `str` à partir d’`index`.
Si `valeur  n’existe pas, `null(int)` est renvoyé.
Si `index` est négatif, l’`index` est calculé à partir de la fin d’`str`.

<a id="func_10"></a>
> next (**StringIterator** *itérateur*) (**string?**)

Avance l’itérateur jusqu’au caractère suivant.

<a id="func_11"></a>
> pop (**string** *str*) (**string?**)

Retire le dernier élément d’`str` et le retourne.
S’il n’existe pas, retourne `null(T)`.

<a id="func_12"></a>
> pop (**string** *str*, **int** *quantité*) (**string**)

Retire `quantité` éléments d’`str` et les retourne.

<a id="func_13"></a>
> push (**string** *str*, **string** *valeur*)

Ajoute `valeur` en fin d’`str`.

<a id="func_14"></a>
> remove (**string** *str*, **int** *index*)

Retire l’élément à l’`index` spécifié.

<a id="func_15"></a>
> remove (**string** *str*, **int** *indexDébut*, **int** *indexFin*)

Retire les éléments de `indexDébut` à `indexFin` inclus.

<a id="func_16"></a>
> reverse (**pure string** *str*) (**string**)

Retourne l’inverse d’`str`.

<a id="func_17"></a>
> shift (**string** *str*) (**string?**)

Retire le premier élément d’`str` et les retourne.
S’il n’existe pas, retourne `null(T)`.

<a id="func_18"></a>
> shift (**string** *str*, **int** *quantité*) (**string**)

Retire les premiers `quantité` éléments d’`str` et les retourne.

<a id="func_19"></a>
> size (**pure string** *str*) (**int**)

Renvoie la taille d’`str`.

<a id="func_20"></a>
> slice (**pure string** *str*, **int** *indexDébut*, **int** *indexFin*) (**string**)

Retourne une portion d’`str` de `indexDébut` jusqu’à `indexFin` inclus.

<a id="func_21"></a>
> unshift (**string** *str*, **string** *valeur*)

Ajoute `valeur` en début d’`str`.

