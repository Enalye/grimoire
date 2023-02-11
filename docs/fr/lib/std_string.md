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
|[clear](#func_0)|*str*: **string**||
|[contains](#func_1)|*str*: **pure string**, *valeur*: **pure string**|**bool**|
|[copy](#func_2)|*str*: **pure string**|**string**|
|[each](#func_3)|*chaîne*: **string**|**StringIterator**|
|[first](#func_4)|*str*: **pure string**|**string?**|
|[indexOf](#func_5)|*str*: **pure string**, *valeur*: **pure string**|**int?**|
|[insert](#func_6)|*liste*: **string**, *index*: **int**, *valeur*: **pure string**||
|[isEmpty](#func_7)|*str*: **pure string**|**bool**|
|[last](#func_8)|*str*: **pure string**|**string?**|
|[lastIndexOf](#func_9)|*str*: **pure string**, *valeur*: **pure string**|**int?**|
|[next](#func_10)|*itérateur*: **StringIterator**|**string?**|
|[pop](#func_11)|*str*: **string**|**string?**|
|[pop](#func_12)|*str*: **string**, *quantité*: **int**|**string**|
|[push](#func_13)|*str*: **string**, *valeur*: **string**||
|[remove](#func_14)|*str*: **string**, *index*: **int**||
|[remove](#func_15)|*str*: **string**, *indexDébut*: **int**, *indexFin*: **int**||
|[reverse](#func_16)|*str*: **pure string**|**string**|
|[shift](#func_17)|*str*: **string**|**string?**|
|[shift](#func_18)|*str*: **string**, *quantité*: **int**|**string**|
|[size](#func_19)|*str*: **pure string**|**int**|
|[slice](#func_20)|*str*: **pure string**, *indexDébut*: **int**, *indexFin*: **int**|**string**|
|[unshift](#func_21)|*str*: **string**, *valeur*: **string**||


***
## Description des fonctions

<a id="func_0"></a>
> clear (*str*: **string**)

Vide la `str`.

<a id="func_1"></a>
> contains (*str*: **pure string**, *valeur*: **pure string**) (**bool**)

Renvoie `true` si `valeur` existe dans `str`.

<a id="func_2"></a>
> copy (*str*: **pure string**) (**string**)

Retourne une copie d’`str`.

<a id="func_3"></a>
> each (*chaîne*: **string**) (**StringIterator**)

Retourne un itérateur qui parcours chaque caractère de la chaîne.

<a id="func_4"></a>
> first (*str*: **pure string**) (**string?**)

Retourne le premier élément d’`str`.
S’il n’existe pas, retourne `null<T>`.

<a id="func_5"></a>
> indexOf (*str*: **pure string**, *valeur*: **pure string**) (**int?**)

Retourne la première occurence de `valeur` dans `str` à partir d’`index`.
Si `valeur`  n’existe pas, `null<int>` est renvoyé.
Si `index` est négatif, l’`index` est calculé à partir de la fin d’`str`.

<a id="func_6"></a>
> insert (*liste*: **string**, *index*: **int**, *valeur*: **pure string**)

Insère `valeur` dans la `str` à l’`index` spécifié.
Si `index` dépasse la taille d’`str`, `valeur` est ajouté en fin d’`str`.
Si `index` est négatif, l’`index` est calculé à partir de la fin d’`str`.

<a id="func_7"></a>
> isEmpty (*str*: **pure string**) (**bool**)

Renvoie `true` si la `str` ne contient rien.

<a id="func_8"></a>
> last (*str*: **pure string**) (**string?**)

Returne le dernier élément d’`str`.
S’il n’existe pas, retourne `null<T>`.

<a id="func_9"></a>
> lastIndexOf (*str*: **pure string**, *valeur*: **pure string**) (**int?**)

Retourne la dernière occurence de `valeur` dans `str` à partir d’`index`.
Si `valeur`  n’existe pas, `null<int>` est renvoyé.
Si `index` est négatif, l’`index` est calculé à partir de la fin d’`str`.

<a id="func_10"></a>
> next (*itérateur*: **StringIterator**) (**string?**)

Avance l’itérateur jusqu’au caractère suivant.

<a id="func_11"></a>
> pop (*str*: **string**) (**string?**)

Retire le dernier élément d’`str` et le retourne.
S’il n’existe pas, retourne `null<T>`.

<a id="func_12"></a>
> pop (*str*: **string**, *quantité*: **int**) (**string**)

Retire `quantité` éléments d’`str` et les retourne.

<a id="func_13"></a>
> push (*str*: **string**, *valeur*: **string**)

Ajoute `valeur` en fin d’`str`.

<a id="func_14"></a>
> remove (*str*: **string**, *index*: **int**)

Retire l’élément à l’`index` spécifié.

<a id="func_15"></a>
> remove (*str*: **string**, *indexDébut*: **int**, *indexFin*: **int**)

Retire les éléments de `indexDébut` à `indexFin` inclus.

<a id="func_16"></a>
> reverse (*str*: **pure string**) (**string**)

Retourne l’inverse d’`str`.

<a id="func_17"></a>
> shift (*str*: **string**) (**string?**)

Retire le premier élément d’`str` et les retourne.
S’il n’existe pas, retourne `null<T>`.

<a id="func_18"></a>
> shift (*str*: **string**, *quantité*: **int**) (**string**)

Retire les premiers `quantité` éléments d’`str` et les retourne.

<a id="func_19"></a>
> size (*str*: **pure string**) (**int**)

Renvoie la taille d’`str`.

<a id="func_20"></a>
> slice (*str*: **pure string**, *indexDébut*: **int**, *indexFin*: **int**) (**string**)

Retourne une portion d’`str` de `indexDébut` jusqu’à `indexFin` inclus.

<a id="func_21"></a>
> unshift (*str*: **string**, *valeur*: **string**)

Ajoute `valeur` en début d’`str`.

