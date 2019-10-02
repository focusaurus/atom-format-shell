# Atom Format Shell

Automatically format/beautify/pretty-print your shell script source code from within the Atom text editor.

The formatting is powered under the hood by [shfmt](https://github.com/mvdan/sh), which must be installed separately from atom and this atom package.

You can install shfmt by [several package managers as documented here](https://github.com/mvdan/sh).

## How to use

There are two ways to format your code:

- Automatically **format on save** (requires enabling in _Packages → Format Shell → Toggle Format on Save_)
- Run the command _Format Shell: Format_ to invoke `shfmt` manually