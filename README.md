# fantasy grounds extensions

Intended as a collection of the extensions I make for fantasy grounds

In order to use any of these extensions, they need to be placed into the extensions folder for fantasy grounds:

`<DISK>:\Users\<USER>\AppData\Roaming\SmiteWorks\Fantasy Grounds\extensions`

It will then be available for selection when setting up the campaign server

## True Expressions

True expressions is intended to improving expression calculation by reading character data as real numbers.

In order to use this, some parts are required:

When defining the action effect in the character sheet, you must define which character the data will be collected from. This is done by adding [NAME|Character name] in the expression with everything else.

Supported values that can be collected are:

* [CLVL]
* [CSTR]
* [CDEX]
* [CCON]
* [CINT]
* [CWIS]
* [CCHA]

An example:
`Heavy Attack; ATK: 1 + [CCON]; [NAME|Character Name]`
