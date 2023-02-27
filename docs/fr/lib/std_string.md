# std.string

Type de base.
## Description
Type pouvant contenir des caractères UTF-8.
## Natifs
### Bytes
Itère sur chaque octet d’une chaîne.
### Chars
Itère sur les points de code d’une chaîne.
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[back](#func_0)|*self*: **pure string**|**char?**|
|[bytes](#func_1)|*self*: **string**|**Bytes**|
|[chars](#func_2)|*chaîne*: **string**|**Chars**|
|[clear](#func_3)|*self*: **string**||
|[contains](#func_4)|*self*: **pure string**, *str*: **pure string**|**bool**|
|[copy](#func_5)|*self*: **pure string**|**string**|
|[find](#func_6)|*self*: **pure string**, *str*: **pure string**|**uint?**|
|[find](#func_7)|*self*: **pure string**, *str*: **pure string**, *idx*: **int**|**uint?**|
|[front](#func_8)|*self*: **pure string**|**char?**|
|[insert](#func_9)|*self*: **string**, *at*: **int**, *ch*: **pure string**||
|[isEmpty](#func_10)|*self*: **pure string**|**bool**|
|[next](#func_11)|*it*: **Bytes**|**int?**|
|[next](#func_12)|*itérateur*: **Chars**|**char?**|
|[popBack](#func_13)|*self*: **string**|**char?**|
|[popBack](#func_14)|*self*: **string**, *count*: **int**|**string**|
|[popFront](#func_15)|*self*: **string**|**char?**|
|[popFront](#func_16)|*self*: **string**, *count*: **int**|**string**|
|[pushBack](#func_17)|*self*: **string**, *str*: **string**||
|[pushFront](#func_18)|*self*: **string**, *str*: **string**||
|[remove](#func_19)|*self*: **string**, *at*: **int**||
|[remove](#func_20)|*self*: **string**, *start*: **int**, *end*: **int**||
|[reverse](#func_21)|*str*: **pure string**|**string**|
|[rfind](#func_22)|*self*: **pure string**, *str*: **pure string**|**uint?**|
|[rfind](#func_23)|*self*: **pure string**, *str*: **pure string**, *idx*: **int**|**uint?**|
|[size](#func_24)|*self*: **pure string**|**uint**|
|[slice](#func_25)|*self*: **pure string**, *start*: **int**, *end*: **int**|**string**|


***
## Description des fonctions

<a id="func_0"></a>
> back (*self*: **pure string**) (**char?**)

Returne le dernier élément de la chaîne.
Retourne `null<char>` si la chaîne est vide.

<a id="func_1"></a>
> bytes (*self*: **string**) (**Bytes**)

Retourne un itérateur qui parcours chaque octet de la chaîne.

<a id="func_2"></a>
> chars (*chaîne*: **string**) (**Chars**)

Retourne un itérateur qui parcours chaque point de code.

<a id="func_3"></a>
> clear (*self*: **string**)

Vide le contenu de la chaîne.

<a id="func_4"></a>
> contains (*self*: **pure string**, *str*: **pure string**) (**bool**)

Renvoie `true` si `str` existe dans la chaîne.

<a id="func_5"></a>
> copy (*self*: **pure string**) (**string**)

Retourne une copie de le chaîne.

<a id="func_6"></a>
> find (*self*: **pure string**, *str*: **pure string**) (**uint?**)

Retourne la première occurence de `str` dans la chaîne.
Si `valeur`  n’existe pas, `null<uint>` est renvoyé.
Si `index` est négatif, l’`index` est calculé à partir de la fin de la chaîne.

<a id="func_7"></a>
> find (*self*: **pure string**, *str*: **pure string**, *idx*: **int**) (**uint?**)

Retourne la première occurence de `str` dans la chaîne à partir de `idx`.
Si `valeur`  n’existe pas, `null<uint>` est renvoyé.
Si `index` est négatif, l’`index` est calculé à partir de la fin de la chaîne.

<a id="func_8"></a>
> front (*self*: **pure string**) (**char?**)

Retourne le premier caractère de la chaîne.
Retourne `null<char>` si la chaîne est vide.

<a id="func_9"></a>
> insert (*self*: **string**, *at*: **int**, *ch*: **pure string**)

Insère un caractère dans la chaîne à l’index spécifié.
Si l’index dépasse la taille de la chaîne, il est ajouté à la fin.
Si l’index est négatif, il est calculé à partir de la fin.

<a id="func_10"></a>
> isEmpty (*self*: **pure string**) (**bool**)

Renvoie `true` si la chaîne est vide.

<a id="func_11"></a>
> next (*it*: **Bytes**) (**int?**)

Avance l’itérateur jusqu’à l’octet suivant.

<a id="func_12"></a>
> next (*itérateur*: **Chars**) (**char?**)

Avance l’itérateur jusqu’au caractère suivant.

<a id="func_13"></a>
> popBack (*self*: **string**) (**char?**)

Retire le dernier caractère de la chaîne et le retourne.
Retourne `null<char>` si la chaîne est vide.

<a id="func_14"></a>
> popBack (*self*: **string**, *count*: **int**) (**string**)

Retire N caractères de la chaîne et les retourne.

<a id="func_15"></a>
> popFront (*self*: **string**) (**char?**)

Retire le premier caractère de la chaîne et le retourne.
Retourne `null<char>` si la chaîne est vide.

<a id="func_16"></a>
> popFront (*self*: **string**, *count*: **int**) (**string**)

Retire les X premiers caractères de la chaîne et les retourne.

<a id="func_17"></a>
> pushBack (*self*: **string**, *str*: **string**)

Ajoute `str` à la fin de la chaîne.

<a id="func_18"></a>
> pushFront (*self*: **string**, *str*: **string**)

Ajoute `str` au début de la chaîne.

<a id="func_19"></a>
> remove (*self*: **string**, *at*: **int**)

Retire le caractère à l’index spécifié.

<a id="func_20"></a>
> remove (*self*: **string**, *start*: **int**, *end*: **int**)

Retire les caractères de `start` à `end` inclus.

<a id="func_21"></a>
> reverse (*str*: **pure string**) (**string**)

Retourne une version inversée de la chaîne.

<a id="func_22"></a>
> rfind (*self*: **pure string**, *str*: **pure string**) (**uint?**)

Retourne la dernière occurence de `str` dans la chaîne.
Si `valeur`  n’existe pas, `null<uint>` est renvoyé.
Si `index` est négatif, l’`index` est calculé à partir de la fin de la chaîne.

<a id="func_23"></a>
> rfind (*self*: **pure string**, *str*: **pure string**, *idx*: **int**) (**uint?**)

Retourne la dernière occurence de `str` dans la chaîne à partir de `idx`.
Si `valeur`  n’existe pas, `null<uint>` est renvoyé.
Si `index` est négatif, l’`index` est calculé à partir de la fin de la chaîne.

<a id="func_24"></a>
> size (*self*: **pure string**) (**uint**)

Renvoie la taille de la chaîne en octets.

<a id="func_25"></a>
> slice (*self*: **pure string**, *start*: **int**, *end*: **int**) (**string**)

Retourne une portion de la chaîne de `start` jusqu’à `end` inclus.

