# list

Type de base.

## Description

Une list est une liste de *valeur* d’un même type pouvant être stockées ensemble.

## Fonctions

|Fonction|Entrée|Sortie|
|-|-|-|
|[clear](#clear)|**list(T)** *liste*|**list(T)**|
|[contains](#contains)|**pure list(T)** *liste*, **T** *valeur*|**bool**|
|[copy](#copy)|**pure list(T)** *liste*|**list(T)**|
|[each](#each)|**pure list(T)** *liste*|[ListIterator](#listiterator)\<T\>|
|[fill](#fill)|**list(T)** *liste*, **T** *valeur*|**list(T)**|
|[first](#first)|**list(T)** *liste*|**T**|
|[get](#get)|**pure list(T)** *liste*, **int** *index*|**T?**|
|[getOr](#getOr)|**pure list(T)** *liste*, **int** *index*, **T** *défaut*|**T**|
|[indexOf](#indexOf)|**pure list(T)** *liste*, **pure T** *valeur*|**int?**|
|[insert](#insert)|**list(T)** *liste*, **int** *index*, **T** *valeur*|**list(T)**|
|[isEmpty](#isEmpty)|**pure list(T)** *liste*|**bool**|
|[lastIndexOf](#lastIndexOf)|**pure list(T)** *liste*, **pure T** *valeur*|**int?**|
|[last](#last)|**pure list(T)** *liste*|**T?**|
|[pop](#pop_1)|**list(T)** *liste*|**T?**|
|[pop](#pop_2)|**list(T)** *liste*, **int** *quantité*|**list(T)**|
|[push](#push)|**list(T)** *liste*, **T** *valeur*||
|[remove](#remove_1)|**list(T)** *liste*, **int** *index*||
|[remove](#remove_2)|**list(T)** *liste*, **int** *indexDébut*, **int** *indexFin*||
|[resize](#resize)|**list(T)** *liste*, **int** *taille*||
|[reverse](#reverse)|**pure list(T)** *liste*|**list(T)**|
|[shift](#shift_1)|**list(T)** *liste*|**T**|
|[shift](#shift_2)|**list(T)** *liste*, **int** *quantité*|**list(T)**|
|[size](#size)|**pure list(T)** *liste*|**int**|
|[slice](#slice)|**pure list(T)** *liste*, **int** *indexDébut*, **int** *indexFin*|**list(list(T))**|
|[sort](#sort_i)|**list(int)** *liste*||
|[sort](#sort_r)|**list(real)** *liste*||
|[sort](#sort_s)|**list(string)** *liste*||
|[unshift](#unshift)|**list(T)** *liste*, **T** *valeur*|**list(T)**|

## Description des fonctions

<a id="clear"></a>
- clear (**list(T)** *liste*) (**list(T)**)

Vide la liste.
___

<a id="contains"></a>
- contains (**pure list(T)** *liste*, **T** *valeur*) (**bool**)

Renvoie `true` si `valeur` est présent dans la liste.
___

<a id="copy"></a>
- copy (**pure list(T)** *liste*) (**list(T)**)

Retourne une copie de la liste.
___

<a id="each"></a>
- each (**list(T)** *liste*) (**[ListIterator](#listiterator)**)

Retourne un itérateur itérant à travers chaque élément de la liste.
___

<a id="fill"></a>
- fill (**list(T)** *liste*, **T** *valeur*) (**list(T)**)

Remplace le contenu de la liste par `valeur`.
___

<a id="first"></a>
- first (**pure list(T)** *liste*) (**T**)

Retourne le premier élément de la liste.
___

<a id="get"></a>
- get (**pure list(T)** *liste*, **int** *index*) (**T?**)

Retourne l’élément à l’`index` indiqué, s’il existe.
Sinon, retourne `null(T)`.
Si `index` est négatif, l’`index` est calculé à partir de la fin de la liste.
___

<a id="getOr"></a>
- getOr (**pure list(T)** *liste*, **int** *index*, **T** *défaut*) (**T?**)

Retourne l’élément à l’`index` indiqué, s’il existe.
Sinon, retourne la valeur par `défaut`.
Si `index` est négatif, l’`index` est calculé à partir de la fin de la liste.
___

<a id="indexOf"></a>
- indexOf (**pure list(T)** *liste*, **pure T** *valeur*) (**int?**)

Si `valeur` est trouvé dans la liste, returne l’index du premier élement trouvé, sinon `null(int)` est renvoyé.
Si `index` est négatif, l’`index` est calculé à partir de la fin de la liste.
___

<a id="insert"></a>
- insert (**list(T)** *liste*, **int** *index*, **T** *valeur*) (**list(T)**)

Insère `valeur` dans la liste à l’`index` spécifié.
Si `index` dépasse la taille de la liste, `valeur` est ajouté en fin de liste.
Si `index` est négatif, l’`index` est calculé à partir de la fin de la liste.
___

<a id="isEmpty"></a>
- isEmpty (**pure list(T)** *liste*) (**bool**)

Renvoie `true` si la liste ne contient rien.
___

<a id="lastIndexOf"></a>
- lastIndexOf (**pure list(T)** *liste*, **pure T** *valeur*) (**int?**)

Si `valeur` est trouvé dans la liste, returne l’index du dernier élement trouvé, sinon `null(int)` est renvoyé.
Si `index` est négatif, l’`index` est calculé à partir de la fin de la liste.
___

<a id="last"></a>
- last (**pure list(T)** *liste*) (**T?**)

Returne le dernier élément de la liste.
S’il n’existe pas, retourne `null(T)`.
___

<a id="pop_1"></a>
- pop (**list(T)** *liste*) (**T?**)

Retire le dernier élément de la liste et les retourne.
S’il n’existe pas, retourne `null(T)`.
___

<a id="pop_2"></a>
- pop (**list(T)** *liste*, **int** *quantité*) (**list(T)**)

Retire `quantité` éléments de la liste et les retourne.
___

<a id="push"></a>
- push (**list(T)** *liste*, **T** *valeur*)

Ajoute `valeur` en fin de liste.
___

<a id="remove_1"></a>
- remove (**list(T)** *liste*, **int** *index*)

Retire l’élément à l’`index` spécifié.
___

<a id="remove_2"></a>
- remove (**list(T)** *liste*, **int** *indexDébut*, **int** *indexFin*)

Retire les éléments de `indexDébut` à `indexFin` inclus.
___

<a id="resize"></a>
- resize (**list(T)** *liste*, **int** *taille*)

Redimmensionne la liste.
___

<a id="reverse"></a>
- reverse (**pure list(T)** *liste*) (**list(T)**)

Retourne l’inverse de la liste.
___

<a id="shift_1"></a>
- shift (**list(T)** *liste*) (**T?**)

Retire le premier élément de la liste.
___

<a id="shift_2"></a>
- shift (**list(T)** *liste*, **int** *quantité*) (**list(T)**)

Retire les premiers `quantité` éléments de la liste.
___

<a id="size"></a>
- size (**pure list(T)** *liste*) (**int**)

Renvoie la taille de la liste.
___

<a id="slice"></a>
- slice (**pure list(T)** *liste*, **int** *indexDébut*, **int** *indexFin*) (**list(T)**)

Retourne une portion de la liste de `indexDébut` jusqu’à `indexFin` inclus.
___

<a id="sort_i"></a>
- sort (**list(int)** *liste*)

Trie la liste.
___

<a id="sort_r"></a>
- sort (**list(real)** *liste*)

Trie la liste.
___

<a id="sort_s"></a>
- sort (**list(string)** *liste*)

Trie la liste.
___

<a id="unshift"></a>
- unshift (**list(T)** *liste*, **T** *valeur*)

Ajoute `valeur` en début de liste.
___

# ListIterator

## Description

Fournit un moyen d’itérer sur les éléments d’une liste.

## Fonctions

|Fonction|Entrée|Sortie|
|-|-|-|
|[next](#next)|**[ListIterator](#listiterator)\<T\>** *liste*|**T?**|

## Description des fonctions

<a id="next"></a>
- next (**[ListIterator](#listiterator)\<T\>** *itérateur*) (**T?**)

Avance l’itérateur à l’élément suivant.
