# std.circularbuffer

## Natifs
### CircularBuffer\<T>
### CircularBufferIterator\<T>
Itère sur un buffer circulaire.
## Constructeurs
|Constructeur|Entrée|
|-|-|
|**CircularBuffer\<T>**|**int**|
## Fonctions
|Fonction|Entrée|Sortie|
|-|-|-|
|[back](#func_0)|**pure CircularBuffer\<T>** *buffer*|**T?**|
|[capacity](#func_1)|**pure CircularBuffer\<T>** *buffer*|**int**|
|[front](#func_2)|**pure CircularBuffer\<T>** *buffer*|**T?**|
|[isEmpty](#func_3)|**pure CircularBuffer\<T>** *buffer*|**bool**|
|[isFull](#func_4)|**pure CircularBuffer\<T>** *buffer*|**bool**|
|[pop](#func_5)|**CircularBuffer\<T>** *buffer*|**T?**|
|[push](#func_6)|**CircularBuffer\<T>** *buffer*, **T** *valeur*||
|[size](#func_7)|**pure CircularBuffer\<T>** *buffer*|**int**|


***
## Description des fonctions

<a id="func_0"></a>
> back (**pure CircularBuffer\<T>** *buffer*) (**T?**)

Returne le dernier élément de `buffer`.
S’il n’existe pas, retourne `null(T)`.

<a id="func_1"></a>
> capacity (**pure CircularBuffer\<T>** *buffer*) (**int**)

Retourne la capacité maximale du `buffer`.

<a id="func_2"></a>
> front (**pure CircularBuffer\<T>** *buffer*) (**T?**)

Retourne le premier élément de `buffer`.
S’il n’existe pas, retourne `null(T)`.

<a id="func_3"></a>
> isEmpty (**pure CircularBuffer\<T>** *buffer*) (**bool**)

Renvoie `true` si `buffer` ne contient rien.

<a id="func_4"></a>
> isFull (**pure CircularBuffer\<T>** *buffer*) (**bool**)

Renvoie `true` si `buffer` est plein.

<a id="func_5"></a>
> pop (**CircularBuffer\<T>** *buffer*) (**T?**)

Retire un élément du `buffer` et le retourne.
S’il n’en existe pas, retourne `null(T)`.

<a id="func_6"></a>
> push (**CircularBuffer\<T>** *buffer*, **T** *valeur*)

Ajoute `valeur` dans le `buffer`.

<a id="func_7"></a>
> size (**pure CircularBuffer\<T>** *buffer*) (**int**)

Retourne la taille actuelle du `buffer`.

