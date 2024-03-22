# list

Type de base.
## Description
Une liste est une collection de valeurs d’un même type.

## Natifs
### ListIterator\<T>
Itère sur une liste.
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[back](#func_0)|*array*: **pure [T]**|**T?**|
|[clear](#func_1)|*array*: **[T]**||
|[contains](#func_2)|*array*: **pure [T]**, *value*: **pure T**|**bool**|
|[copy](#func_3)|*array*: **pure [T]**|**[T]**|
|[each](#func_4)|*array*: **[T]**|**ListIterator\<T>**|
|[fill](#func_5)|*array*: **[T]**, *value*: **T**||
|[find](#func_6)|*array*: **pure [T]**, *value*: **pure T**|**uint?**|
|[front](#func_7)|*array*: **pure [T]**|**T?**|
|[get](#func_8)|*array*: **pure [T]**, *idx*: **int**|**T?**|
|[getOr](#func_9)|*array*: **pure [T]**, *idx*: **int**, *default*: **T**|**T**|
|[insert](#func_10)|*array*: **[T]**, *idx*: **int**, *value*: **T**||
|[isEmpty](#func_11)|*array*: **pure [T]**|**bool**|
|[next](#func_12)|*iterator*: **ListIterator\<T>**|**T?**|
|[popBack](#func_13)|*array*: **[T]**|**T?**|
|[popBack](#func_14)|*array*: **[T]**, *count*: **int**|**[T]**|
|[popFront](#func_15)|*array*: **[T]**|**T?**|
|[popFront](#func_16)|*array*: **[T]**, *count*: **uint**|**[T]**|
|[pushBack](#func_17)|*array*: **[T]**, *value*: **T**||
|[pushFront](#func_18)|*array*: **[T]**, *value*: **T**||
|[remove](#func_19)|*array*: **[T]**, *idx*: **int**||
|[remove](#func_20)|*array*: **[T]**, *start*: **int**, *end*: **int**||
|[resize](#func_21)|*array*: **[T]**, *length*: **int**, *default*: **T**||
|[reverse](#func_22)|*array*: **pure [T]**|**[T]**|
|[rfind](#func_23)|*array*: **pure [T]**, *value*: **pure T**|**uint?**|
|[size](#func_24)|*array*: **pure [T]**|**int**|
|[slice](#func_25)|*array*: **pure [T]**, *start*: **int**, *end*: **int**|**[T]**|
|[sort](#func_26)|*array*: **[int]**||
|[sort](#func_27)|*array*: **[float]**||
|[sort](#func_28)|*array*: **[string]**||


***
## Description des fonctions

<a id="func_0"></a>
> back(*array*: **pure [T]**) (**T?**)

Returne le dernier élément de la liste.

S’il n’existe pas, retourne `null<T>`.

<a id="func_1"></a>
> clear(*array*: **[T]**)

Vide la liste.

<a id="func_2"></a>
> contains(*array*: **pure [T]**, *value*: **pure T**) (**bool**)

Renvoie `true` si `value` est présent dans la liste.

<a id="func_3"></a>
> copy(*array*: **pure [T]**) (**[T]**)

Retourne une copie de la liste.

<a id="func_4"></a>
> each(*array*: **[T]**) (**ListIterator\<T>**)

Returne un itérateur permettant d’itérer sur chaque élément de la liste.

<a id="func_5"></a>
> fill(*array*: **[T]**, *value*: **T**)

Remplace le contenu de la liste par `value`.

<a id="func_6"></a>
> find(*array*: **pure [T]**, *value*: **pure T**) (**uint?**)

Retourne la première occurence de `value` dans la liste à partir de l’index.

Si `value`  n’existe pas, `null<int>` est renvoyé.

Un index négatif est calculé à partir de la fin de la liste.

<a id="func_7"></a>
> front(*array*: **pure [T]**) (**T?**)

Retourne le premier élément de la liste.

S’il n’existe pas, retourne `null<T>`.

<a id="func_8"></a>
> get(*array*: **pure [T]**, *idx*: **int**) (**T?**)

Retourne l’élément à l’index indiqué, s’il existe.

Sinon, retourne `null<T>`.

Un index négatif est calculé à partir de la fin de la liste.

<a id="func_9"></a>
> getOr(*array*: **pure [T]**, *idx*: **int**, *default*: **T**) (**T**)

Retourne l’élément à l’index indiqué, s’il existe.

Sinon, retourne la value par défaut `default`.

Un index négatif est calculé à partir de la fin de la liste.

<a id="func_10"></a>
> insert(*array*: **[T]**, *idx*: **int**, *value*: **T**)

Insère `value` dans la liste à l’`index` spécifié.

Si `index` dépasse la taille de la liste, `value` est ajouté en fin de the list.

Un index négatif est calculé à partir de la fin de la liste.

<a id="func_11"></a>
> isEmpty(*array*: **pure [T]**) (**bool**)

Renvoie `true` si la liste est vide.

<a id="func_12"></a>
> next(*iterator*: **ListIterator\<T>**) (**T?**)

Avance l’itérateur à l’élément suivant.

<a id="func_13"></a>
> popBack(*array*: **[T]**) (**T?**)

Retire le dernier élément de la liste et le retourne.

S’il n’existe pas, retourne `null<T>`.

<a id="func_14"></a>
> popBack(*array*: **[T]**, *count*: **int**) (**[T]**)

Retire les N derniers éléments de la liste et les retourne.

<a id="func_15"></a>
> popFront(*array*: **[T]**) (**T?**)

Retire le premier élément de la liste et les retourne.

S’il n’existe pas, retourne `null<T>`.

<a id="func_16"></a>
> popFront(*array*: **[T]**, *count*: **uint**) (**[T]**)

Retire les N premiers éléments de la liste et les retourne.

<a id="func_17"></a>
> pushBack(*array*: **[T]**, *value*: **T**)

Ajoute `value` à la fin de la liste.

<a id="func_18"></a>
> pushFront(*array*: **[T]**, *value*: **T**)

Ajoute `value` au début de la liste.

<a id="func_19"></a>
> remove(*array*: **[T]**, *idx*: **int**)

Retire l’élément à l’index spécifié.

Un index négatif est calculé à partir de la fin de la liste.

<a id="func_20"></a>
> remove(*array*: **[T]**, *start*: **int**, *end*: **int**)

Retire les éléments de `start` à `end` inclus.

Un index négatif est calculé à partir de la fin de la liste.

<a id="func_21"></a>
> resize(*array*: **[T]**, *length*: **int**, *default*: **T**)

Redimmensionne la liste.

Si `len` est plus grand que la taille de la liste, l’exédent est initialisé avec `default`.

<a id="func_22"></a>
> reverse(*array*: **pure [T]**) (**[T]**)

Retourne une version inversée de la liste.

<a id="func_23"></a>
> rfind(*array*: **pure [T]**, *value*: **pure T**) (**uint?**)

Retourne la dernière occurence de `value` dans la liste à partir de l’index.

Si `value`  n’existe pas, `null<int>` est renvoyé.

Un index négatif est calculé à partir de la fin de la liste.

<a id="func_24"></a>
> size(*array*: **pure [T]**) (**int**)

Renvoie la taille de la liste.

<a id="func_25"></a>
> slice(*array*: **pure [T]**, *start*: **int**, *end*: **int**) (**[T]**)

Retourne une portion de la liste de `start` jusqu’à `end` inclus.

Un index négatif est calculé à partir de la fin de la liste.

<a id="func_26"></a>
> sort(*array*: **[int]**)

Trie la liste.

<a id="func_27"></a>
> sort(*array*: **[float]**)

Trie la liste.

<a id="func_28"></a>
> sort(*array*: **[string]**)

Trie la liste.

