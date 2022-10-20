# **string**

Type de base.

## Description

Type pouvant contenir des caractères UTF-8.

## Fonctions

|Fonction|Entrée|Sortie|
|-|-|-|
|[contains](#contains)|**pure string** *chaîne*, **pure string** *valeur*|**string**|
|[copy](#copy)|**pure string** *chaîne*|**string**|
|[each](#each)|**pure string**|**[StringIterator](#stringiterator)**|
|[first](#first)|**pure string** *chaîne*|**string**|
|[indexOf](#indexOf)|**pure string** *chaîne*, **string** *valeur*|**int**|
|[insert](#insert)|**string** *chaîne*, **int** *index*, **string** *valeur*|**string**|
|[isEmpty](#isEmpty)|**string** *chaîne*|**bool**|
|[lastIndexOf](#lastIndexOf)|**string** *chaîne*, **string** *valeur*|**int**|
|[last](#last)|**string** *chaîne*|**string**|
|[pop](#pop_1)|**string** *chaîne*|**string**|
|[pop](#pop_2)|**string** *chaîne*, **int** *quantité*|**string**|
|[push](#push)|**string** *chaîne*, **string** *valeur*|**string**|
|[remove](#remove)|**string** *chaîne*, **int** *index*|**string**|
|[remove](#remove)|**string** *chaîne*, **int** *indexDébut*, **int** *indexFin*|**string**|
|[reverse](#reverse)|**string** *chaîne*|**string**|
|[shift](#shift_1)|**string** *chaîne*|**string**|
|[shift](#shift_2)|**string** *chaîne*, **int** *quantité*|**string**|
|[size](#size)|**pure string** *chaîne*|**int**|
|[slice](#slice)|**string** *chaîne*, **int** *indexDébut*, **int** *indexFin*|**string**|
|[unshift](#unshift)|**string** *chaîne*, **string** *valeur*|**string**|

## Description des fonctions

<a id="each"></a>
- each ( **string** *chaîne* ) ( [StringIterator](#stringiterator) )

Returns an iterator that iterate through each character.
___

<a id="empty"></a>
- empty? ( **string** *chaîne* ) ( **bool** )

Returns `true` if the **string** has no character.
___

<a id="indexOf"></a>
- indexOf ( **string** *chaîne*, **string** *valeur* ) ( **int** )

If `*valeur*` is found inside the **string**, returns the *index* of the first element found, otherwise -1 is returned.
___

<a id="lastIndexOf"></a>
- lastIndexOf ( **string** *chaîne*, **string** *valeur* ) ( **int** )

If `*valeur*` is found inside the **string**, returns the *index* of the last element found, otherwise -1 is returned.
___

<a id="first"></a>
- first ( **string** *chaîne* ) ( **string** )

Returns the first character of the **string**.
___

<a id="has"></a>
- has? ( **string** *chaîne*, **string** *valeur* ) ( **bool** )

Returns `true` if the `*valeur*` is found inside the **string**.
___

<a id="insert"></a>
- insert ( **string** *chaîne*, **int** *index*, **string** *valeur* ) ( **string** )

Insert the `*valeur*` to the **string** at the specified `*index*`.
___

<a id="last"></a>
- last ( **string** *chaîne* ) ( **string** )

Returns the last character of the **string**.
___

<a id="pop_1"></a>
- pop ( **string** *chaîne* ) ( **string** )

Remove the last element from the **string**.
___

<a id="pop_2"></a>
- pop ( **string** *chaîne*, **int** *quantité* ) ( **string** )

Remove the last `*quantité*` element from the **string**.
___

<a id="push"></a>
- push ( **string** *chaîne*, [**string**](#**string**] *valeur* ) ( **string** )

Append the `*valeur*` at the end of the **string**.
___

<a id="remove"></a>
- remove ( **string** *chaîne*, **int** *index* ) ( **string** )

Delete the element at `*index*`.
___

<a id="remove"></a>
- remove ( **string** *chaîne*, **int** *indexDébut*, **int** *indexFin* ) ( **string** )

Delete the elements between `*indexDébut*` and `*indexFin*` included.
___

<a id="reverse"></a>
- reverse ( **string** *chaîne* ) ( **string** )

Invert the **string**.
___

<a id="shift_1"></a>
- shift ( **string** *chaîne* ) ( **string** )

Remove the first element from the **string**.
___

<a id="shift_2"></a>
- shift ( **string** *chaîne*, **int** *quantité* ) ( **string** )

Remove the first `*quantité*` element from the **string**.
___

<a id="slice"></a>
- slice ( **string** *chaîne*, **int** *indexDébut*, **int** *indexFin* ) ( **string** )

Returns the **string** from `*indexDébut*` to `*indexFin*` included.
___

<a id="split"></a>
- split ( **string**(T) *chaîne*, T *valeur* ) ( **string** )

Remove the first `*quantité*` element from the **string**.
___

<a id="unshift"></a>
- unshift ( **string** *chaîne*, **string** *valeur* ) ( list(**string**) )

Prepend the `*valeur*` at the beginning of the **string**.
___

# StringIterator

## Description

Provides a way to iterate through an list.

## Fonctions

|Fonction|Entrée|Sortie|
|-|-|-|
|[next](#next)|[StringIterator](#stringiterator) *chaîne*|**bool**, **string**|

## Description des fonctions

<a id="next"></a>
- next ( [StringIterator](#stringiterator) ) ( **bool**, **string** )

Advance the iterator to the next element.
Returns `true` while the iterator hasn't reach the end and the current element.