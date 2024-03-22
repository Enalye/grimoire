# string

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
|[back](#func_0)|*str*: **pure string**|**char?**|
|[bytes](#func_1)|*str*: **string**|**Bytes**|
|[chars](#func_2)|*str*: **string**|**Chars**|
|[clear](#func_3)|*str*: **string**||
|[contains](#func_4)|*str*: **pure string**, *substr*: **pure string**|**bool**|
|[copy](#func_5)|*str*: **pure string**|**string**|
|[find](#func_6)|*str*: **pure string**, *substr*: **pure string**|**uint?**|
|[find](#func_7)|*str*: **pure string**, *substr*: **pure string**, *idx*: **int**|**uint?**|
|[front](#func_8)|*str*: **pure string**|**char?**|
|[insert](#func_9)|*str*: **string**, *idx*: **int**, *substr*: **pure string**||
|[insert](#func_10)|*str*: **string**, *idx*: **int**, *ch*: **char**||
|[isEmpty](#func_11)|*str*: **pure string**|**bool**|
|[next](#func_12)|*iterator*: **Bytes**|**byte?**|
|[next](#func_13)|*iterator*: **Chars**|**char?**|
|[popBack](#func_14)|*str*: **string**|**char?**|
|[popBack](#func_15)|*str*: **string**, *count*: **int**|**string**|
|[popFront](#func_16)|*str*: **string**|**char?**|
|[popFront](#func_17)|*str*: **string**, *count*: **int**|**string**|
|[pushBack](#func_18)|*str1*: **string**, *str2*: **pure string**||
|[pushBack](#func_19)|*str*: **string**, *ch*: **char**||
|[pushFront](#func_20)|*str1*: **string**, *str2*: **pure string**||
|[pushFront](#func_21)|*str*: **string**, *ch*: **char**||
|[remove](#func_22)|*str*: **string**, *idx*: **int**||
|[remove](#func_23)|*str*: **string**, *start*: **int**, *end*: **int**||
|[reverse](#func_24)|*str*: **pure string**|**string**|
|[rfind](#func_25)|*str*: **pure string**, *substr*: **pure string**|**uint?**|
|[rfind](#func_26)|*str*: **pure string**, *substr*: **pure string**, *idx*: **int**|**uint?**|
|[size](#func_27)|*str*: **pure string**|**uint**|
|[slice](#func_28)|*str*: **pure string**, *start*: **int**, *end*: **int**|**string**|


***
## Description des fonctions

<a id="func_0"></a>
> back(*str*: **pure string**) (**char?**)

Returne le dernier caractère de la chaîne.

Retourne `null<char>` si la chaîne est vide.

<a id="func_1"></a>
> bytes(*str*: **string**) (**Bytes**)

Retourne un itérateur qui parcours chaque octet de la chaîne.

<a id="func_2"></a>
> chars(*str*: **string**) (**Chars**)

Retourne un itérateur qui parcours chaque point de code.

<a id="func_3"></a>
> clear(*str*: **string**)

Vide le contenu de la chaîne.

<a id="func_4"></a>
> contains(*str*: **pure string**, *substr*: **pure string**) (**bool**)

Renvoie `true` si `str` existe dans la chaîne.

<a id="func_5"></a>
> copy(*str*: **pure string**) (**string**)

Retourne une copie de la chaîne.

<a id="func_6"></a>
> find(*str*: **pure string**, *substr*: **pure string**) (**uint?**)

Retourne la première occurence de `substr` dans la chaîne.

Si `valeur`  n’existe pas, `null<uint>` est renvoyé.

Si `index` est négatif, l’`index` est calculé à partir de la fin de la chaîne.

<a id="func_7"></a>
> find(*str*: **pure string**, *substr*: **pure string**, *idx*: **int**) (**uint?**)

Retourne la première occurence de `substr` dans la chaîne à partir de `idx` (en octets).

Si `valeur`  n’existe pas, `null<uint>` est renvoyé.

Si `index` est négatif, l’`index` est calculé à partir de la fin de la chaîne.

<a id="func_8"></a>
> front(*str*: **pure string**) (**char?**)

Retourne le premier caractère de la chaîne.

Retourne `null<char>` si la chaîne est vide.

<a id="func_9"></a>
> insert(*str*: **string**, *idx*: **int**, *substr*: **pure string**)

Insère `substr` dans la chaîne à l’index spécifié (en octets).

Si l’index dépasse la taille de la chaîne, il est ajouté à la fin.

Si l’index est négatif, il est calculé à partir de la fin.

Si un index ne tombe pas sur un caractère, sa position sera celle du prochain caractère valide.

<a id="func_10"></a>
> insert(*str*: **string**, *idx*: **int**, *ch*: **char**)

Insère un caractère dans la chaîne à l’index spécifié (en octets).

Si l’index dépasse la taille de la chaîne, il est ajouté à la fin.

Si l’index est négatif, il est calculé à partir de la fin.

Si un index ne tombe pas sur un caractère, sa position sera celle du prochain caractère valide.

<a id="func_11"></a>
> isEmpty(*str*: **pure string**) (**bool**)

Renvoie `true` si la chaîne est vide.

<a id="func_12"></a>
> next(*iterator*: **Bytes**) (**byte?**)

Avance l’itérateur jusqu’à l’octet suivant.

<a id="func_13"></a>
> next(*iterator*: **Chars**) (**char?**)

Avance l’itérateur jusqu’au caractère suivant.

<a id="func_14"></a>
> popBack(*str*: **string**) (**char?**)

Retire le dernier caractère de la chaîne et le retourne.

Retourne `null<char>` si la chaîne est vide.

<a id="func_15"></a>
> popBack(*str*: **string**, *count*: **int**) (**string**)

Retire N caractères de la chaîne et les retourne.

<a id="func_16"></a>
> popFront(*str*: **string**) (**char?**)

Retire le premier caractère de la chaîne et le retourne.

Retourne `null<char>` si la chaîne est vide.

<a id="func_17"></a>
> popFront(*str*: **string**, *count*: **int**) (**string**)

Retire les X premiers caractères de la chaîne et les retourne.

<a id="func_18"></a>
> pushBack(*str1*: **string**, *str2*: **pure string**)

Ajoute `str2` à la fin de la chaîne.

<a id="func_19"></a>
> pushBack(*str*: **string**, *ch*: **char**)

Ajoute `ch` à la fin de la chaîne.

<a id="func_20"></a>
> pushFront(*str1*: **string**, *str2*: **pure string**)

Ajoute `str2` au début de la chaîne.

<a id="func_21"></a>
> pushFront(*str*: **string**, *ch*: **char**)

Ajoute `ch` au début de la chaîne.

<a id="func_22"></a>
> remove(*str*: **string**, *idx*: **int**)

Retire un caractère à la position en octet spécifiée.

Si l’index est négatif, il est calculé à partir de la fin.

Si l’index ne tombe pas sur un caractère, sa position sera celle du prochain caractère valide.

<a id="func_23"></a>
> remove(*str*: **string**, *start*: **int**, *end*: **int**)

Retire les caractères de `start` à `end` (en octets) inclus.

Les index négatifs sont calculés à partir de la fin de la chaîne.

Si un index ne tombe pas sur un caractère, sa position sera celle du prochain caractère valide.

<a id="func_24"></a>
> reverse(*str*: **pure string**) (**string**)

Retourne une version inversée de la chaîne.

<a id="func_25"></a>
> rfind(*str*: **pure string**, *substr*: **pure string**) (**uint?**)

Retourne la dernière occurence de `substr` dans la chaîne.

Si `valeur`  n’existe pas, `null<uint>` est renvoyé.

Si `index` est négatif, l’`index` est calculé à partir de la fin de la chaîne.

<a id="func_26"></a>
> rfind(*str*: **pure string**, *substr*: **pure string**, *idx*: **int**) (**uint?**)

Retourne la dernière occurence de `substr` dans la chaîne à partir de `idx` (en octets).

Si `valeur`  n’existe pas, `null<uint>` est renvoyé.

Si `index` est négatif, l’`index` est calculé à partir de la fin de la chaîne.

<a id="func_27"></a>
> size(*str*: **pure string**) (**uint**)

Renvoie la taille de la chaîne en octets.

<a id="func_28"></a>
> slice(*str*: **pure string**, *start*: **int**, *end*: **int**) (**string**)

Retourne une portion de la chaîne de `start` jusqu’à `end` (en octets) inclus.

Les index négatifs sont calculés à partir de la fin de la chaîne.

Si un index ne tombe pas sur un caractère, sa position sera celle du prochain caractère valide.

