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
|[back](#func_0)|*self*: **pure [T]**|**T?**|
|[clear](#func_1)|*self*: **[T]**||
|[contains](#func_2)|*self*: **pure [T]**, *value*: **pure T**|**bool**|
|[copy](#func_3)|*self*: **pure [T]**|**[T]**|
|[each](#func_4)|*self*: **[T]**|**ListIterator\<T>**|
|[fill](#func_5)|*self*: **[T]**, *value*: **T**||
|[find](#func_6)|*self*: **pure [T]**, *value*: **pure T**|**uint?**|
|[front](#func_7)|*self*: **pure [T]**|**T?**|
|[get](#func_8)|*self*: **pure [T]**, *idx*: **int**|**T?**|
|[getOr](#func_9)|*self*: **pure [T]**, *idx*: **int**, *def*: **T**|**T**|
|[insert](#func_10)|*self*: **[T]**, *idx*: **int**, *value*: **T**||
|[isEmpty](#func_11)|*self*: **pure [T]**|**bool**|
|[next](#func_12)|*itérateur*: **ListIterator\<T>**|**T?**|
|[popBack](#func_13)|*self*: **[T]**|**T?**|
|[popBack](#func_14)|*self*: **[T]**, *count*: **int**|**[T]**|
|[popFront](#func_15)|*self*: **[T]**|**T?**|
|[popFront](#func_16)|*self*: **[T]**, *count*: **uint**|**[T]**|
|[pushBack](#func_17)|*self*: **[T]**, *value*: **T**||
|[pushFront](#func_18)|*self*: **[T]**, *value*: **T**||
|[remove](#func_19)|*self*: **[T]**, *idx*: **int**||
|[remove](#func_20)|*self*: **[T]**, *start*: **int**, *end*: **int**||
|[resize](#func_21)|*self*: **[T]**, *len*: **int**, *def*: **T**||
|[reverse](#func_22)|*self*: **pure [T]**|**[T]**|
|[rfind](#func_23)|*self*: **pure [T]**, *value*: **pure T**|**uint?**|
|[size](#func_24)|*self*: **pure [T]**|**int**|
|[slice](#func_25)|*self*: **pure [T]**, *start*: **int**, *end*: **int**|**[T]**|
|[sort](#func_26)|*self*: **[int]**||
|[sort](#func_27)|*self*: **[float]**||
|[sort](#func_28)|*self*: **[string]**||


***
## Description des fonctions

<a id="func_0"></a>
> back (*self*: **pure [T]**) (**T?**)

Returne le dernier élément de la liste.

S’il n’existe pas, retourne `null<T>`.

<a id="func_1"></a>
> clear (*self*: **[T]**)

Vide la liste.

<a id="func_2"></a>
> contains (*self*: **pure [T]**, *value*: **pure T**) (**bool**)

Renvoie `true` si `value` est présent dans la liste.

<a id="func_3"></a>
> copy (*self*: **pure [T]**) (**[T]**)

Retourne une copie de la liste.

<a id="func_4"></a>
> each (*self*: **[T]**) (**ListIterator\<T>**)

Returne un itérateur permettant d’itérer sur chaque élément de la liste.

<a id="func_5"></a>
> fill (*self*: **[T]**, *value*: **T**)

Remplace le contenu de la liste par `value`.

<a id="func_6"></a>
> find (*self*: **pure [T]**, *value*: **pure T**) (**uint?**)

Retourne la première occurence de `value` dans la liste à partir de l’index.

Si `value`  n’existe pas, `null<int>` est renvoyé.

Un index négatif est calculé à partir de la fin de la liste.

<a id="func_7"></a>
> front (*self*: **pure [T]**) (**T?**)

Retourne le premier élément de la liste.

S’il n’existe pas, retourne `null<T>`.

<a id="func_8"></a>
> get (*self*: **pure [T]**, *idx*: **int**) (**T?**)

Retourne l’élément à l’index indiqué, s’il existe.

Sinon, retourne `null<T>`.

Un index négatif est calculé à partir de la fin de la liste.

<a id="func_9"></a>
> getOr (*self*: **pure [T]**, *idx*: **int**, *def*: **T**) (**T**)

Retourne l’élément à l’index indiqué, s’il existe.

Sinon, retourne la value par défaut `def`.

Un index négatif est calculé à partir de la fin de la liste.

<a id="func_10"></a>
> insert (*self*: **[T]**, *idx*: **int**, *value*: **T**)

Insère `value` dans la liste à l’`index` spécifié.

Si `index` dépasse la taille de la liste, `value` est ajouté en fin de the list.

Un index négatif est calculé à partir de la fin de la liste.

<a id="func_11"></a>
> isEmpty (*self*: **pure [T]**) (**bool**)

Renvoie `true` si la liste est vide.

<a id="func_12"></a>
> next (*itérateur*: **ListIterator\<T>**) (**T?**)

Avance l’itérateur à l’élément suivant.

<a id="func_13"></a>
> popBack (*self*: **[T]**) (**T?**)

Retire le dernier élément de la liste et le retourne.

S’il n’existe pas, retourne `null<T>`.

<a id="func_14"></a>
> popBack (*self*: **[T]**, *count*: **int**) (**[T]**)

Retire les N derniers éléments de la liste et les retourne.

<a id="func_15"></a>
> popFront (*self*: **[T]**) (**T?**)

Retire le premier élément de la liste et les retourne.

S’il n’existe pas, retourne `null<T>`.

<a id="func_16"></a>
> popFront (*self*: **[T]**, *count*: **uint**) (**[T]**)

Retire les N premiers éléments de la liste et les retourne.

<a id="func_17"></a>
> pushBack (*self*: **[T]**, *value*: **T**)

Ajoute `value` à la fin de la liste.

<a id="func_18"></a>
> pushFront (*self*: **[T]**, *value*: **T**)

Ajoute `value` au début de la liste.

<a id="func_19"></a>
> remove (*self*: **[T]**, *idx*: **int**)

Retire l’élément à l’index spécifié.

Un index négatif est calculé à partir de la fin de la liste.

<a id="func_20"></a>
> remove (*self*: **[T]**, *start*: **int**, *end*: **int**)

Retire les éléments de `start` à `end` inclus.

Un index négatif est calculé à partir de la fin de la liste.

<a id="func_21"></a>
> resize (*self*: **[T]**, *len*: **int**, *def*: **T**)

Redimmensionne la liste.

Si `len` est plus grand que la taille de la liste, l’exédent est initialisé avec `def`.

<a id="func_22"></a>
> reverse (*self*: **pure [T]**) (**[T]**)

Retourne une version inversée de la liste.

<a id="func_23"></a>
> rfind (*self*: **pure [T]**, *value*: **pure T**) (**uint?**)

Retourne la dernière occurence de `value` dans la liste à partir de l’index.

Si `value`  n’existe pas, `null<int>` est renvoyé.

Un index négatif est calculé à partir de la fin de la liste.

<a id="func_24"></a>
> size (*self*: **pure [T]**) (**int**)

Renvoie la taille de la liste.

<a id="func_25"></a>
> slice (*self*: **pure [T]**, *start*: **int**, *end*: **int**) (**[T]**)

Retourne une portion de la liste de `start` jusqu’à `end` inclus.

Un index négatif est calculé à partir de la fin de la liste.

<a id="func_26"></a>
> sort (*self*: **[int]**)

Trie la liste.

<a id="func_27"></a>
> sort (*self*: **[float]**)

Trie la liste.

<a id="func_28"></a>
> sort (*self*: **[string]**)

Trie la liste.

