# fantasy grounds extensions

Intended as a collection of the extensions I make for fantasy grounds

In order to use any of these extensions, they need to be placed into the extensions folder for fantasy grounds:

`<DISK>:\Users\<USER>\AppData\Roaming\SmiteWorks\Fantasy Grounds\extensions`

It will then be available for selection when setting up the campaign server

## True Expressions

True expressions is intended to improving expression calculation by reading character data as real numbers

This extension is intended for Fantasy Grounds Unity, running Pathfinder 1e

In order to use this, some parts are required:

When defining the action effect in the character sheet, you must define which character the data will be collected from. This is done by adding `[NAME|Character name]` in the expression with everything else

Supported values that can be collected are:

* [LVL]
* [STR]
* [DEX]
* [CON]
* [INT]
* [WIS]
* [CHA]

An example:
`Heavy Attack; ATK: 1 + [CON]; [NAME|Character Name]`

Arithmetic tools are also available

* min(x, y)
* max(x, y)
* mul(x, y)
* div(x, y)
* cos(x)
* floor(x)
* ceil(x)

Example:
`Arcane Strike; ATK: 1 + div([LVL],4); [NAME|Character Name]`

Please note that no calculus will be perfomed unless the modifier is numerical or rollable

Numerical calculations will preroll dice, while rollable calculations will leave this to Fantasy Grounds

Mainly this replaces the PC Specific. The rest should work as before:

[Fantasy Grounds Effects](https://fantasygroundsunity.atlassian.net/wiki/spaces/FGU/pages/950877/PFRPG+and+3.5E+Effects)
