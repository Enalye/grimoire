# string

Built-in type.
## Description
Type that contains UTF-8 characters.
## Natives
### Bytes
Iterates on each byte of a string.
### Chars
Iterates on code points of a string.
## Functions
|Function|Input|Output|
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
## Function descriptions

<a id="func_0"></a>
> back(*str*: **pure string**) (**char?**)

Returns the last character of the string.

Returns `null<char>` if this string is empty.

<a id="func_1"></a>
> bytes(*str*: **string**) (**Bytes**)

Returns an iterator that iterate through each byte.

<a id="func_2"></a>
> chars(*str*: **string**) (**Chars**)

Returns an iterator that iterate through each code point.

<a id="func_3"></a>
> clear(*str*: **string**)

Clear the content of the string.

<a id="func_4"></a>
> contains(*str*: **pure string**, *substr*: **pure string**) (**bool**)

Returns `true` if `str` exists in the string.

<a id="func_5"></a>
> copy(*str*: **pure string**) (**string**)

Returns a copy of the string.

<a id="func_6"></a>
> find(*str*: **pure string**, *substr*: **pure string**) (**uint?**)

Returns the first occurence of `value` in the string.

If `value` does't exist, `null<uint>` is returned.

If `index` is negative, `index` is calculated from the back of the string.

<a id="func_7"></a>
> find(*str*: **pure string**, *substr*: **pure string**, *idx*: **int**) (**uint?**)

Returns the first occurence of `value` in the string, starting from `idx` (in bytes).

If `value` does't exist, `null<uint>` is returned.

If `index` is negative, `index` is calculated from the back of the string.

<a id="func_8"></a>
> front(*str*: **pure string**) (**char?**)

Returns the first character of the string.

Returns `null<char>` if this string is empty.

<a id="func_9"></a>
> insert(*str*: **string**, *idx*: **int**, *substr*: **pure string**)

Insert `substr` in the string at the specified index (in bytes).

If the index is greater than the size of the string, it's appended at the back.

If the index is negative, the index is calculated from the back.

If an index does not fall on a character, it'll be adjusted to the next valid character.

<a id="func_10"></a>
> insert(*str*: **string**, *idx*: **int**, *ch*: **char**)

Insert a character in the string at the specified index (in bytes).

If the index is greater than the size of the string, it's appended at the back.

If the index is negative, the index is calculated from the back.

If an index does not fall on a character, it'll be adjusted to the next valid character.

<a id="func_11"></a>
> isEmpty(*str*: **pure string**) (**bool**)

Returns `true` if the string is empty.

<a id="func_12"></a>
> next(*iterator*: **Bytes**) (**byte?**)

Advances the iterator until the next byte.

<a id="func_13"></a>
> next(*iterator*: **Chars**) (**char?**)

Advances the iterator until the next character.

<a id="func_14"></a>
> popBack(*str*: **string**) (**char?**)

Removes the last character of the string and returns it.

Returns `null<char>` if this string is empty.

<a id="func_15"></a>
> popBack(*str*: **string**, *count*: **int**) (**string**)

Removes N characters from the string and returns them.

<a id="func_16"></a>
> popFront(*str*: **string**) (**char?**)

Removes the first character of the string and returns it.

Returns `null<char>` if this string is empty.

<a id="func_17"></a>
> popFront(*str*: **string**, *count*: **int**) (**string**)

Removes the first X characters from the string and returns them.

<a id="func_18"></a>
> pushBack(*str1*: **string**, *str2*: **pure string**)

Appends `str2` at the back of the string.

<a id="func_19"></a>
> pushBack(*str*: **string**, *ch*: **char**)

Appends `ch` at the back of the string.

<a id="func_20"></a>
> pushFront(*str1*: **string**, *str2*: **pure string**)

Prepends `str2` at the front of the string.

<a id="func_21"></a>
> pushFront(*str*: **string**, *ch*: **char**)

Prepends `ch` at the front of the string.

<a id="func_22"></a>
> remove(*str*: **string**, *idx*: **int**)

Removes a character at the specified byte position.

If the index is negative, it is calculated from the back of the string.

If the index does not fall on a character, it'll be adjusted to the next valid character.

<a id="func_23"></a>
> remove(*str*: **string**, *start*: **int**, *end*: **int**)

Removes the characters from `start` to `end` (in bytes) included.

Negative indexes are calculated from the back of the string.

If an index does not fall on a character, it'll be adjusted to the next valid character.

<a id="func_24"></a>
> reverse(*str*: **pure string**) (**string**)

Returns an inverted version of the string.

<a id="func_25"></a>
> rfind(*str*: **pure string**, *substr*: **pure string**) (**uint?**)

Returns the last occurence of `str` in the string.

If `value` does't exist, `null<uint>` is returned.

If `index` is negative, `index` is calculated from the back of the string.

<a id="func_26"></a>
> rfind(*str*: **pure string**, *substr*: **pure string**, *idx*: **int**) (**uint?**)

Returns the last occurence of `substr` in the string, starting from `idx` (in bytes).

If `value` does't exist, `null<uint>` is returned.

If `index` is negative, `index` is calculated from the back of the string.

<a id="func_27"></a>
> size(*str*: **pure string**) (**uint**)

Returns the size of the string in bytes.

<a id="func_28"></a>
> slice(*str*: **pure string**, *start*: **int**, *end*: **int**) (**string**)

Returns a slice of the string from `start` to `end` (in bytes) included.

Negative indexes are calculated from the back of the string.

If an index does not fall on a character, it'll be adjusted to the next valid character.

