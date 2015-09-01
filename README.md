GraphQL
=======

GraphQL parser for Elixir.

See [GraphQL Spec](http://facebook.github.io/graphql/)

Implementation
--------------

Plan is to see whether [leex](http://erlang.org/doc/man/leex.html) and [yecc](http://erlang.org/doc/man/yecc.html) will fit the bill.

Some resources on using leex and yecc

* http://relops.com/blog/2014/01/13/leex_and_yecc/
* http://andrealeopardi.com/posts/tokenizing-and-parsing-in-elixir-using-leex-and-yecc/


Developers
----------

### Atom Editor Support

>  Using the `language-babel` package? `.xrl` and `.yrl` files not syntax highlighting?

Syntax highlighting in Atom for `leex` (`.xrl`) and `yecc` (`yrl`) can be added by modifying `grammars/erlang.cson`.

Just open the `atom-language-erlang` package code in Atom and make the change described here:

https://github.com/jonathanmarvens/atom-language-erlang/pull/11

however if that PR has been merged then just grab the latest version of the plugin!
