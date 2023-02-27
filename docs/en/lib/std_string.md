# std.string

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
|[back](#func_0)|*self*: **pure string**|**char?**|
|[bytes](#func_1)|*self*: **string**|**Bytes**|
|[chars](#func_2)|*str*: **string**|**Chars**|
|[clear](#func_3)|*self*: **string**||
|[contains](#func_4)|*self*: **pure string**, *str*: **pure string**|**bool**|
|[copy](#func_5)|*self*: **pure string**|**string**|
|[find](#func_6)|*self*: **pure string**, *str*: **pure string**|**uint?**|
|[find](#func_7)|*self*: **pure string**, *str*: **pure string**, *idx*: **int**|**uint?**|
|[front](#func_8)|*self*: **pure string**|**char?**|
|[insert](#func_9)|*self*: **string**, *idx*: **int**, *str*: **pure string**||
|[insert](#func_10)|*self*: **string**, *idx*: **int**, *ch*: **char**||
|[isEmpty](#func_11)|*self*: **pure string**|**bool**|
|[next](#func_12)|*it*: **Bytes**|**int?**|
|[next](#func_13)|*iterator*: **Chars**|**char?**|
|[popBack](#func_14)|*self*: **string**|**char?**|
|[popBack](#func_15)|*self*: **string**, *count*: **int**|**string**|
|[popFront](#func_16)|*self*: **string**|**char?**|
|[popFront](#func_17)|*self*: **string**, *count*: **int**|**string**|
|[pushBack](#func_18)|*self*: **string**, *ch*: **pure string**||
|[pushBack](#func_19)|*self*: **string**, *ch*: **char**||
|[pushFront](#func_20)|*self*: **string**, *str*: **pure string**||
|[pushFront](#func_21)|*self*: **string**, *ch*: **char**||
|[remove](#func_22)|*self*: **string**, *idx*: **int**||
|[remove](#func_23)|*self*: **string**, *start*: **int**, *end*: **int**||
|[reverse](#func_24)|*str*: **pure string**|**string**|
|[rfind](#func_25)|*self*: **pure string**, *str*: **pure string**|**uint?**|
|[rfind](#func_26)|*self*: **pure string**, *str*: **pure string**, *idx*: **int**|**uint?**|
|[size](#func_27)|*self*: **pure string**|**uint**|
|[slice](#func_28)|*self*: **pure string**, *start*: **int**, *end*: **int**|**string**|


***
## Function descriptions

<a id="func_0"></a>
> back (*self*: **pure string**) (**char?**)

Returns the last character of the string.

Returns `null<char>` if this string is empty.

<a id="func_1"></a>
> bytes (*self*: **string**) (**Bytes**)

Returns an iterator that iterate through each byte.

<a id="func_2"></a>
> chars (*str*: **string**) (**Chars**)

Returns an iterator that iterate through each code point.

<a id="func_3"></a>
> clear (*self*: **string**)

Clear the content of the string.

<a id="func_4"></a>
> contains (*self*: **pure string**, *str*: **pure string**) (**bool**)

Returns `true` if `str` exists in the string.

<a id="func_5"></a>
> copy (*self*: **pure string**) (**string**)

Returns a copy of the string.

<a id="func_6"></a>
> find (*self*: **pure string**, *str*: **pure string**) (**uint?**)

Returns the first occurence of `value` in the string.

If `value` does't exist, `null<uint>` is returned.

If `index` is negative, `index` is calculated from the back of the string.

<a id="func_7"></a>
> find (*self*: **pure string**, *str*: **pure string**, *idx*: **int**) (**uint?**)

Returns the first occurence of `value` in the string, starting from `idx` (in bytes).

If `value` does't exist, `null<uint>` is returned.

If `index` is negative, `index` is calculated from the back of the string.

<a id="func_8"></a>
> front (*self*: **pure string**) (**char?**)

Returns the first character of the string.

Returns `null<char>` if this string is empty.

<a id="func_9"></a>
> insert (*self*: **string**, *idx*: **int**, *str*: **pure string**)

Insert `str` in the string at the specified index (in bytes).

If the index is greater than the size of the string, it's appended at the back.

If the index is negative, the index is calculated from the back.

If an index does not fall on a character, it'll be adjusted to the next valid character.

<a id="func_10"></a>
> insert (*self*: **string**, *idx*: **int**, *ch*: **char**)

Insert a character in the string at the specified index (in bytes).

If the index is greater than the size of the string, it's appended at the back.

If the index is negative, the index is calculated from the back.

If an index does not fall on a character, it'll be adjusted to the next valid character.

<a id="func_11"></a>
> isEmpty (*self*: **pure string**) (**bool**)

Returns `true` if the string is empty.

<a id="func_12"></a>
> next (*it*: **Bytes**) (**int?**)

Advances the iterator until the next byte.

<a id="func_13"></a>
> next (*iterator*: **Chars**) (**char?**)

Advances the iterator until the next character.

<a id="func_14"></a>
> popBack (*self*: **string**) (**char?**)

Removes the last character of the string and returns it.

Returns `null<char>` if this string is empty.

<a id="func_15"></a>
> popBack (*self*: **string**, *count*: **int**) (**string**)

Removes N characters from the string and returns them.

<a id="func_16"></a>
> popFront (*self*: **string**) (**char?**)

Removes the first character of the string and returns it.

Returns `null<char>` if this string is empty.

<a id="func_17"></a>
> popFront (*self*: **string**, *count*: **int**) (**string**)

Removes the first X characters from the string and returns them.

<a id="func_18"></a>
> pushBack (*self*: **string**, *ch*: **pure string**)

Appends `str` at the back of the string.

<a id="func_19"></a>
> pushBack (*self*: **string**, *ch*: **char**)

Appends `ch` at the back of the string.

<a id="func_20"></a>
> pushFront (*self*: **string**, *str*: **pure string**)

Prepends `str` at the front of the string.

<a id="func_21"></a>
> pushFront (*self*: **string**, *ch*: **char**)

Prepends `ch` at the front of the string.

<a id="func_22"></a>
> remove (*self*: **string**, *idx*: **int**)

Removes a character at the specified byte position.

If the index is negative, it is calculated from the back of the string.

If the index does not fall on a character, it'll be adjusted to the next valid character.

<a id="func_23"></a>
> remove (*self*: **string**, *start*: **int**, *end*: **int**)

Removes the characters from `start` to `end` (in bytes) included.

Negative indexes are calculated from the back of the string.

If an index does not fall on a character, it'll be adjusted to the next valid character.

<a id="func_24"></a>
> reverse (*str*: **pure string**) (**string**)

Returns an inverted version of the string.

<a id="func_25"></a>
> rfind (*self*: **pure string**, *str*: **pure string**) (**uint?**)

Returns the last occurence of `str` in the string.

If `value` does't exist, `null<uint>` is returned.

If `index` is negative, `index` is calculated from the back of the string.

<a id="func_26"></a>
> rfind (*self*: **pure string**, *str*: **pure string**, *idx*: **int**) (**uint?**)

Returns the last occurence of `str` in the string, starting from `idx` (in bytes).

If `value` does't exist, `null<uint>` is returned.

If `index` is negative, `index` is calculated from the back of the string.

<a id="func_27"></a>
> size (*self*: **pure string**) (**uint**)

Returns the size of the string in bytes.

<a id="func_28"></a>
> slice (*self*: **pure string**, *start*: **int**, *end*: **int**) (**string**)

Returns a slice of the string from `start` to `end` (in bytes) included.

Negative indexes are calculated from the back of the string.

If an index does not fall on a character, it'll be adjusted to the next valid character.

