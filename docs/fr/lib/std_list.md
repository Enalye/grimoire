# std.list

Type de base.
## Description
list est une collection de valeurs d’un même type.
## Natifs
### ListIterator\<T>
Itère sur une liste.
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[clear](#func_0)|*lst*: **list\<T>**||
|[contains](#func_1)|*lst*: **pure list\<T>**, *valeur*: **pure T**|**bool**|
|[copy](#func_2)|*lst*: **pure list\<T>**|**list\<T>**|
|[each](#func_3)|*lst*: **list\<T>**|**ListIterator\<T>**|
|[fill](#func_4)|*lst*: **list\<T>**, *valeur*: **T**||
|[first](#func_5)|*lst*: **pure list\<T>**|**T?**|
|[get](#func_6)|*lst*: **pure list\<T>**, *index*: **int**|**T?**|
|[getOr](#func_7)|*lst*: **pure list\<T>**, *index*: **int**, *défaut*: **T**|**T**|
|[indexOf](#func_8)|*lst*: **pure list\<T>**, *valeur*: **pure T**|**int?**|
|[insert](#func_9)|*lst*: **list\<T>**, *index*: **int**, *valeur*: **T**||
|[isEmpty](#func_10)|*lst*: **pure list\<T>**|**bool**|
|[last](#func_11)|*lst*: **pure list\<T>**|**T?**|
|[lastIndexOf](#func_12)|*lst*: **pure list\<T>**, *valeur*: **pure T**|**int?**|
|[next](#func_13)|*itérateur*: **ListIterator\<T>**|**T?**|
|[pop](#func_14)|*lst*: **list\<T>**|**T?**|
|[pop](#func_15)|*lst*: **list\<T>**, *quantité*: **int**|**list\<T>**|
|[push](#func_16)|*lst*: **list\<T>**, *valeur*: **T**||
|[remove](#func_17)|*lst*: **list\<T>**, *index*: **int**||
|[remove](#func_18)|*lst*: **list\<T>**, *indexDébut*: **int**, *indexFin*: **int**||
|[resize](#func_19)|*lst*: **list\<T>**, *taille*: **int**, *défaut*: **T**||
|[reverse](#func_20)|*lst*: **pure list\<T>**|**list\<T>**|
|[shift](#func_21)|*lst*: **list\<T>**|**T?**|
|[shift](#func_22)|*lst*: **list\<T>**, *quantité*: **int**|**list\<T>**|
|[size](#func_23)|*lst*: **pure list\<T>**|**int**|
|[slice](#func_24)|*lst*: **pure list\<T>**, *indexDébut*: **int**, *indexFin*: **int**|**list\<T>**|
|[sort](#func_25)|*lst*: **list\<int>**||
|[sort](#func_26)|*lst*: **list\<float>**||
|[sort](#func_27)|*lst*: **list\<string>**||
|[unshift](#func_28)|*lst*: **list\<T>**, *valeur*: **T**||


***
## Description des fonctions

<a id="func_0"></a>
> clear (*lst*: **list\<T>**)

Vide la `lst`.

<a id="func_1"></a>
> contains (*lst*: **pure list\<T>**, *valeur*: **pure T**) (**bool**)

Renvoie `true` si `valeur` est présent dans la `lst`.

<a id="func_2"></a>
> copy (*lst*: **pure list\<T>**) (**list\<T>**)

Retourne une copie d’`lst`.

<a id="func_3"></a>
> each (*lst*: **list\<T>**) (**ListIterator\<T>**)

Returne un itérateur permettant d’itérer sur chaque élément d’`lst`.

<a id="func_4"></a>
> fill (*lst*: **list\<T>**, *valeur*: **T**)

Remplace le contenu d’`lst` par `valeur`.

<a id="func_5"></a>
> first (*lst*: **pure list\<T>**) (**T?**)

Retourne le premier élément d’`lst`.
S’il n’existe pas, retourne `null(T)`.

<a id="func_6"></a>
> get (*lst*: **pure list\<T>**, *index*: **int**) (**T?**)

Retourne l’élément à l’`index` indiqué, s’il existe.
Sinon, retourne `null(T)`.
Si `index` est négatif, l’`index` est calculé à partir de la fin d’`lst`.

<a id="func_7"></a>
> getOr (*lst*: **pure list\<T>**, *index*: **int**, *défaut*: **T**) (**T**)

Retourne l’élément à l’`index` indiqué, s’il existe.
Sinon, retourne la valeur par `défaut`.
Si `index` est négatif, l’`index` est calculé à partir de la fin d’`lst`.

<a id="func_8"></a>
> indexOf (*lst*: **pure list\<T>**, *valeur*: **pure T**) (**int?**)

Retourne la première occurence de `valeur` dans la `lst` à partir d’`index`.
Si `valeur  n’existe pas, `null(int)` est renvoyé.
Si `index` est négatif, l’`index` est calculé à partir de la fin d’`lst`.

<a id="func_9"></a>
> insert (*lst*: **list\<T>**, *index*: **int**, *valeur*: **T**)

Insère `valeur` dans la `lst` à l’`index` spécifié.
Si `index` dépasse la taille d’`lst`, `valeur` est ajouté en fin de `lst`.
Si `index` est négatif, l’`index` est calculé à partir de la fin d’`lst`.

<a id="func_10"></a>
> isEmpty (*lst*: **pure list\<T>**) (**bool**)

Renvoie `true` si la `lst` ne contient rien.

<a id="func_11"></a>
> last (*lst*: **pure list\<T>**) (**T?**)

Returne le dernier élément d’`lst`.
S’il n’existe pas, retourne `null(T)`.

<a id="func_12"></a>
> lastIndexOf (*lst*: **pure list\<T>**, *valeur*: **pure T**) (**int?**)

Retourne la dernière occurence de `valeur` dans la `lst` à partir d’`index`.
Si `valeur  n’existe pas, `null(int)` est renvoyé.
Si `index` est négatif, l’`index` est calculé à partir de la fin d’`lst`.

<a id="func_13"></a>
> next (*itérateur*: **ListIterator\<T>**) (**T?**)

Avance l’itérateur à l’élément suivant.

<a id="func_14"></a>
> pop (*lst*: **list\<T>**) (**T?**)

Retire le dernier élément d’`lst` et le retourne.
S’il n’existe pas, retourne `null(T)`.

<a id="func_15"></a>
> pop (*lst*: **list\<T>**, *quantité*: **int**) (**list\<T>**)

Retire `quantité` éléments d’`lst` et les retourne.

<a id="func_16"></a>
> push (*lst*: **list\<T>**, *valeur*: **T**)

Ajoute `valeur` en fin de `lst`.

<a id="func_17"></a>
> remove (*lst*: **list\<T>**, *index*: **int**)

Retire l’élément à l’`index` spécifié.

<a id="func_18"></a>
> remove (*lst*: **list\<T>**, *indexDébut*: **int**, *indexFin*: **int**)

Retire les éléments de `indexDébut` à `indexFin` inclus.

<a id="func_19"></a>
> resize (*lst*: **list\<T>**, *taille*: **int**, *défaut*: **T**)

Redimmensionne la `lst`.
Si `taille` dépasse la taille d’`lst`, l’exédent est initialisé à `défaut`.

<a id="func_20"></a>
> reverse (*lst*: **pure list\<T>**) (**list\<T>**)

Retourne l’inverse d’`lst`.

<a id="func_21"></a>
> shift (*lst*: **list\<T>**) (**T?**)

Retire le premier élément d’`lst` et les retourne.
S’il n’existe pas, retourne `null(T)`.

<a id="func_22"></a>
> shift (*lst*: **list\<T>**, *quantité*: **int**) (**list\<T>**)

Retire les premiers `quantité` éléments d’`lst` et les retourne.

<a id="func_23"></a>
> size (*lst*: **pure list\<T>**) (**int**)

Renvoie la taille d’`lst`.

<a id="func_24"></a>
> slice (*lst*: **pure list\<T>**, *indexDébut*: **int**, *indexFin*: **int**) (**list\<T>**)

Retourne une portion d’`lst` de `indexDébut` jusqu’à `indexFin` inclus.

<a id="func_25"></a>
> sort (*lst*: **list\<int>**)

Trie la `lst`.

<a id="func_26"></a>
> sort (*lst*: **list\<float>**)

Trie la `lst`.

<a id="func_27"></a>
> sort (*lst*: **list\<string>**)

Trie la `lst`.

<a id="func_28"></a>
> unshift (*lst*: **list\<T>**, *valeur*: **T**)

Ajoute `valeur` en début de `lst`.

