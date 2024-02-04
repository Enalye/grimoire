# circularbuffer

## Natifs
### CircularBuffer\<T>
### CircularBufferIterator\<T>
Itère sur un buffer circulaire.
## Constructeurs
|Fonction|Entrée|
|-|-|
|[@**CircularBuffer\<T>**](#ctor_0)| *param0*: **int**|
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[back](#func_0)|*buffer*: **pure CircularBuffer\<T>**|**T?**|
|[capacity](#func_1)|*buffer*: **pure CircularBuffer\<T>**|**int**|
|[front](#func_2)|*buffer*: **pure CircularBuffer\<T>**|**T?**|
|[isEmpty](#func_3)|*buffer*: **pure CircularBuffer\<T>**|**bool**|
|[isFull](#func_4)|*buffer*: **pure CircularBuffer\<T>**|**bool**|
|[pop](#func_5)|*buffer*: **CircularBuffer\<T>**|**T?**|
|[push](#func_6)|*buffer*: **CircularBuffer\<T>**, *value*: **T**||
|[size](#func_7)|*buffer*: **pure CircularBuffer\<T>**|**int**|


***
## Description des fonctions

<a id="func_0"></a>
> back(*buffer*: **pure CircularBuffer\<T>**) (**T?**)

Returne le dernier élément de `buffer`.

S’il n’existe pas, retourne `null<T>`.

<a id="func_1"></a>
> capacity(*buffer*: **pure CircularBuffer\<T>**) (**int**)

Retourne la capacité maximale du `buffer`.

<a id="func_2"></a>
> front(*buffer*: **pure CircularBuffer\<T>**) (**T?**)

Retourne le premier élément de `buffer`.

S’il n’existe pas, retourne `null<T>`.

<a id="func_3"></a>
> isEmpty(*buffer*: **pure CircularBuffer\<T>**) (**bool**)

Renvoie `true` si `buffer` ne contient rien.

<a id="func_4"></a>
> isFull(*buffer*: **pure CircularBuffer\<T>**) (**bool**)

Renvoie `true` si `buffer` est plein.

<a id="func_5"></a>
> pop(*buffer*: **CircularBuffer\<T>**) (**T?**)

Retire un élément du `buffer` et le retourne.

S’il n’en existe pas, retourne `null<T>`.

<a id="func_6"></a>
> push(*buffer*: **CircularBuffer\<T>**, *value*: **T**)

Ajoute `valeur` dans le `buffer`.

<a id="func_7"></a>
> size(*buffer*: **pure CircularBuffer\<T>**) (**int**)

Retourne la taille actuelle du `buffer`.

