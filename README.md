# GraphQL Elixir

[![Build Status](https://travis-ci.org/joshprice/graphql-elixir.svg)](https://travis-ci.org/joshprice/graphql-elixir)
[![Public Slack Discussion](https://graphql-slack.herokuapp.com/badge.svg)](https://graphql-slack.herokuapp.com/)

An Elixir implementation of Facebook's GraphQL.

This is the core GraphQL query parsing and execution engine whose goal is to be
transport, server and datastore agnostic.

In order to setup an HTTP server (ie Phoenix) to handle GraphQL queries you will need [plug_graphql](https://github.com/joshprice/plug_graphql).

Other ways of handling queries will be added in due course.

## Installation

First, add GraphQL to your `mix.exs` dependencies:

```elixir
defp deps do
  [{:graphql, "~> 0.0.5"}]
end
```

Then, update your dependencies:

```sh-session
$ mix deps.get
```

## Usage

First setup your schema

```elixir
defmodule TestSchema do
  def schema do
    %GraphQL.Schema{
      query: %GraphQL.ObjectType{
        name: "RootQueryType",
        fields: [
          %GraphQL.FieldDefinition{
            name: "greeting",
            type: "String",
            resolve: &greeting/1,
          }
        ]
      }
    }
  end

  def greeting(name: name), do: "Hello, #{name}!"
  def greeting(_), do: greeting(name: "world")
end
```

Execute a simple GraphQL query

```elixir
iex> GraphQL.execute(TestSchema.schema, "{greeting}")
{:ok, %{greeting: "Hello, world!"}}
```

## Status

This is a work in progress, right now here's what is done:

- [x] Parser for GraphQL (including Type definitions)
- [x] AST matching the `graphql-js` types as closely as possible
- [x] Schema definition
- [WIP] Query execution
- [WIP] Query validation
- [ ] Introspection

## Resources

- [GraphQL Spec](http://facebook.github.io/graphql/) This incredibly well written spec made writing the GraphQL parser pretty straightforward.
- [GraphQL JS Reference Implementation](https://github.com/graphql/graphql-js)

## Implementation

Tokenisation is done with [leex](http://erlang.org/doc/man/leex.html) and parsing with [yecc](http://erlang.org/doc/man/yecc.html). Both very useful Erlang tools for parsing. Yecc in particular is used by Elixir itself.

Some resources on using leex and yecc:

* http://relops.com/blog/2014/01/13/leex_and_yecc/
* http://andrealeopardi.com/posts/tokenizing-and-parsing-in-elixir-using-leex-and-yecc/

## Developers

### Getting Started

Clone the repo and fetch its dependencies:

```
$ git clone https://github.com/joshprice/graphql-elixir.git
$ cd graphql-elixir
$ mix deps.get
$ mix test
```

### Atom Editor Support

>  Using the `language-erlang` package? `.xrl` and `.yrl` files not syntax highlighting?

Syntax highlighting in Atom for `leex` (`.xrl`) and `yecc` (`yrl`) can be added by modifying `grammars/erlang.cson`.

Just open the `atom-language-erlang` package code in Atom and make the change described here:

https://github.com/jonathanmarvens/atom-language-erlang/pull/11

however if that PR has been merged then just grab the latest version of the plugin!

## Contributing

We actively welcome pull requests, bug reports, feedback, issues, questions. Come and chat in the [#erlang channel on Slack](https://graphql-slack.herokuapp.com/)

## License

[BSD](https://github.com/joshprice/graphql-elixir/blob/master/LICENSE).
