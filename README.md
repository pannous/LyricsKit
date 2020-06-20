# LyricsKit

Lyrics submodule for [LyricsX](https://github.com/pannous/LyricsX).


## LRCX file

### Specification

```
<lrcx>              ::= <line> (NEWLINE <line>)*
<line>              ::= <id tag>
                      | <lyric line>
                      | <lyric attachment>
                      | ""

<id tag>            ::= <tag>
<tag>               ::= "[" <tag content> "]"
<tag content>       ::= <tag key>
                      | <tag key> ":" <tag value>
<tag key>           ::= [0-9a-zA-Z_-]+
<tag value>         ::= <character except NEWLINE or "]">+

<lyric line>        ::= <time tag> <character except NEWLINE>*
<lyric attachment>  ::= <time tag> <attachment tag> <attachment body>

<time tag>          ::= "[" (<minute> ":")* <second> ("." <millisecond>)* "]"

<attachment tag>            ::= <tag>
<attachment body>           ::= <plain text attachment>
                              | <index based attachment>
                              | <range based attachment>
<plain text attachment>     ::= <character except NEWLINE>+
<index based attachment>    ::= <index based segment>+
<range based attachment>    ::= <range based segment>+
<index based segment>       ::= "<" <segment value> "," <segment index> ">"
<range based segment>       ::= "<" <segment value> "," <segment range> ">"
<segment value>             ::= <characters except NEWLINE, "," or ">">
<segment index>             ::= <number>
<segment range>             ::= <lowerBound> "," <upperBound>
```

### Predefined tags

Predefined ID tags:

| Tag | Key | Value Type | Description |
| --- | --- | --- | --- |
| title | ti | string | |
| album | al | string | |
| artist | ar | string | |
| offset | offset | integer | |
| length | length | decimal | |

Predefind attachment tags:

| Tag | Key | Value Type | Attachment type | Description |
| --- | --- | --- | --- | --- |
| translation | tr | [RFC 4646](https://www.ietf.org/rfc/rfc4646.txt) | plain text | |
| word time tag | tt | no value | index based (with timestamp in millisecond) | |
| furigana | fu | no value | range based | |
| romaji | ro | no value | range based | |
