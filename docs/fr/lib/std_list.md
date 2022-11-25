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
|[clear](#func_0)|**list\<T>** *lst*||
|[contains](#func_1)|**pure list\<T>** *lst*, **pure T** *valeur*|**bool**|
|[copy](#func_2)|**pure list\<T>** *lst*|**list\<T>**|
|[each](#func_3)|**list\<T>** *lst*|**ListIterator\<T>**|
|[fill](#func_4)|**list\<T>** *lst*, **T** *valeur*||
|[first](#func_5)|**pure list\<T>** *lst*|**T?**|
|[get](#func_6)|**pure list\<T>** *lst*, **int** *index*|**T?**|
|[getOr](#func_7)|**pure list\<T>** *lst*, **int** *index*, **T** *défaut*|**T**|
|[indexOf](#func_8)|**pure list\<T>** *lst*, **pure T** *valeur*|**int?**|
|[insert](#func_9)|**list\<T>** *lst*, **int** *index*, **T** *valeur*||
|[isEmpty](#func_10)|**pure list\<T>** *lst*|**bool**|
|[last](#func_11)|**pure list\<T>** *lst*|**T?**|
|[lastIndexOf](#func_12)|**pure list\<T>** *lst*, **pure T** *valeur*|**int?**|
|[next](#func_13)|**ListIterator\<T>** *itérateur*|**T?**|
|[pop](#func_14)|**list\<T>** *lst*|**T?**|
|[pop](#func_15)|**list\<T>** *lst*, **int** *quantité*|**list\<T>**|
|[push](#func_16)|**list\<T>** *lst*, **T** *valeur*||
|[remove](#func_17)|**list\<T>** *lst*, **int** *index*||
|[remove](#func_18)|**list\<T>** *lst*, **int** *indexDébut*, **int** *indexFin*||
|[resize](#func_19)|**list\<T>** *lst*, **int** *taille*, **T** *défaut*||
|[reverse](#func_20)|**pure list\<T>** *lst*|**list\<T>**|
|[shift](#func_21)|**list\<T>** *lst*|**T?**|
|[shift](#func_22)|**list\<T>** *lst*, **int** *quantité*|**list\<T>**|
|[size](#func_23)|**pure list\<T>** *lst*|**int**|
|[slice](#func_24)|**pure list\<T>** *lst*, **int** *indexDébut*, **int** *indexFin*|**list\<T>**|
|[sort](#func_25)|**list\<int>** *lst*||
|[sort](#func_26)|**list\<float>** *lst*||
|[sort](#func_27)|**list\<string>** *lst*||
|[unshift](#func_28)|**list\<T>** *lst*, **T** *valeur*||


***
## Description des fonctions

<a id="func_0"></a>
> clear (**list\<T>** *lst*)

Vide la `lst`.

<a id="func_1"></a>
> contains (**pure list\<T>** *lst*, **pure T** *valeur*) (**bool**)

Renvoie `true` si `valeur` est présent dans la `lst`.

<a id="func_2"></a>
> copy (**pure list\<T>** *lst*) (**list\<T>**)

Retourne une copie d’`lst`.

<a id="func_3"></a>
> each (**list\<T>** *lst*) (**ListIterator\<T>**)

Returne un itérateur permettant d’itérer sur chaque élément d’`lst`.

<a id="func_4"></a>
> fill (**list\<T>** *lst*, **T** *valeur*)

Remplace le contenu d’`lst` par `valeur`.

<a id="func_5"></a>
> first (**pure list\<T>** *lst*) (**T?**)

Retourne le premier élément d’`lst`.
S’il n’existe pas, retourne `null(T)`.

<a id="func_6"></a>
> get (**pure list\<T>** *lst*, **int** *index*) (**T?**)

Retourne l’élément à l’`index` indiqué, s’il existe.
Sinon, retourne `null(T)`.
Si `index` est négatif, l’`index` est calculé à partir de la fin d’`lst`.

<a id="func_7"></a>
> getOr (**pure list\<T>** *lst*, **int** *index*, **T** *défaut*) (**T**)

Retourne l’élément à l’`index` indiqué, s’il existe.
Sinon, retourne la valeur par `défaut`.
Si `index` est négatif, l’`index` est calculé à partir de la fin d’`lst`.

<a id="func_8"></a>
> indexOf (**pure list\<T>** *lst*, **pure T** *valeur*) (**int?**)

Retourne la première occurence de `valeur` dans la `lst` à partir d’`index`.
Si `valeur  n’existe pas, `null(int)` est renvoyé.
Si `index` est négatif, l’`index` est calculé à partir de la fin d’`lst`.

<a id="func_9"></a>
> insert (**list\<T>** *lst*, **int** *index*, **T** *valeur*)

Insère `valeur` dans la `lst` à l’`index` spécifié.
Si `index` dépasse la taille d’`lst`, `valeur` est ajouté en fin de `lst`.
Si `index` est négatif, l’`index` est calculé à partir de la fin d’`lst`.

<a id="func_10"></a>
> isEmpty (**pure list\<T>** *lst*) (**bool**)

Renvoie `true` si la `lst` ne contient rien.

<a id="func_11"></a>
> last (**pure list\<T>** *lst*) (**T?**)

Returne le dernier élément d’`lst`.
S’il n’existe pas, retourne `null(T)`.

<a id="func_12"></a>
> lastIndexOf (**pure list\<T>** *lst*, **pure T** *valeur*) (**int?**)

Retourne la dernière occurence de `valeur` dans la `lst` à partir d’`index`.
Si `valeur  n’existe pas, `null(int)` est renvoyé.
Si `index` est négatif, l’`index` est calculé à partir de la fin d’`lst`.

<a id="func_13"></a>
> next (**ListIterator\<T>** *itérateur*) (**T?**)

Avance l’itérateur à l’élément suivant.

<a id="func_14"></a>
> pop (**list\<T>** *lst*) (**T?**)

Retire le dernier élément d’`lst` et le retourne.
S’il n’existe pas, retourne `null(T)`.

<a id="func_15"></a>
> pop (**list\<T>** *lst*, **int** *quantité*) (**list\<T>**)

Retire `quantité` éléments d’`lst` et les retourne.

<a id="func_16"></a>
> push (**list\<T>** *lst*, **T** *valeur*)

Ajoute `valeur` en fin de `lst`.

<a id="func_17"></a>
> remove (**list\<T>** *lst*, **int** *index*)

Retire l’élément à l’`index` spécifié.

<a id="func_18"></a>
> remove (**list\<T>** *lst*, **int** *indexDébut*, **int** *indexFin*)

Retire les éléments de `indexDébut` à `indexFin` inclus.

<a id="func_19"></a>
> resize (**list\<T>** *lst*, **int** *taille*, **T** *défaut*)

Redimmensionne la `lst`.
Si `taille` dépasse la taille d’`lst`, l’exédent est initialisé à `défaut`.

<a id="func_20"></a>
> reverse (**pure list\<T>** *lst*) (**list\<T>**)

Retourne l’inverse d’`lst`.

<a id="func_21"></a>
> shift (**list\<T>** *lst*) (**T?**)

Retire le premier élément d’`lst` et les retourne.
S’il n’existe pas, retourne `null(T)`.

<a id="func_22"></a>
> shift (**list\<T>** *lst*, **int** *quantité*) (**list\<T>**)

Retire les premiers `quantité` éléments d’`lst` et les retourne.

<a id="func_23"></a>
> size (**pure list\<T>** *lst*) (**int**)

Renvoie la taille d’`lst`.

<a id="func_24"></a>
> slice (**pure list\<T>** *lst*, **int** *indexDébut*, **int** *indexFin*) (**list\<T>**)

Retourne une portion d’`lst` de `indexDébut` jusqu’à `indexFin` inclus.

<a id="func_25"></a>
> sort (**list\<int>** *lst*)

Trie la `lst`.

<a id="func_26"></a>
> sort (**list\<float>** *lst*)

Trie la `lst`.

<a id="func_27"></a>
> sort (**list\<string>** *lst*)

Trie la `lst`.

<a id="func_28"></a>
> unshift (**list\<T>** *lst*, **T** *valeur*)

Ajoute `valeur` en début de `lst`.

