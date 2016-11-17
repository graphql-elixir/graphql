# GraphQL Elixir

[![Build Status](https://travis-ci.org/graphql-elixir/graphql.svg)](https://travis-ci.org/graphql-elixir/graphql)
[![Public Slack Discussion](https://graphql-slack.herokuapp.com/badge.svg)](https://graphql-slack.herokuapp.com/)

An Elixir implementation of Facebook's GraphQL.

This is the core GraphQL query parsing and execution engine whose goal is to be
transport, server and datastore agnostic.

In order to setup an HTTP server (ie Phoenix) to handle GraphQL queries you will
need [plug_graphql](https://github.com/graphql-elixir/plug_graphql).
Examples for Phoenix can be found at [hello_graphql_phoenix](https://github.com/graphql-elixir/hello_graphql_phoenix), so look here for a starting point for writing your own schemas.

Other ways of handling queries will be added in due course.

## Installation

First, add GraphQL to your `mix.exs` dependencies:

```elixir
defp deps do
  [{:graphql, "~> 0.3"}]
end
```

Add GraphQL to your `mix.exs` applications:

```elixir
def application do
  # Add the application to your list of applications.
  # This will ensure that it will be included in a release.
  [applications: [:logger, :graphql]]
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
      query: %GraphQL.Type.ObjectType{
        name: "RootQueryType",
        fields: %{
          greeting: %{
            type: %GraphQL.Type.String{},
            resolve: &TestSchema.greeting/3,
            description: "Greeting",
            args: %{
              name: %{type: %GraphQL.Type.String{}, description: "The name of who you'd like to greet."},
            }
          }
        }
      }
    }
  end

  def greeting(_, %{name: name}, _), do: "Hello, #{name}!"
  def greeting(_, _, _), do: "Hello, world!"
end
```

Execute a simple GraphQL query

```elixir
iex> GraphQL.execute(TestSchema.schema, "{greeting}")
{:ok, %{data: %{"greeting" => "Hello, world!"}}}
```

## Status

This is a work in progress, right now here's what is done:

- [x] Parser for GraphQL (including Type definitions)
- [x] AST matching the `graphql-js` types as closely as possible
- [x] Schema definition
- [x] Query execution
  - [x] Scalar types
  - [x] Arguments
  - [x] Multiple forms of resolution
  - [x] Complex types (List, Object, etc)
  - [x] Fragments in queries
  - [x] Extract variable values
- [x] Introspection
- [WIP] Query validation
- [ ] Directives

## Resources

- [GraphQL Spec](http://facebook.github.io/graphql/) This incredibly well written spec made writing the GraphQL parser pretty straightforward.
- [GraphQL JS Reference Implementation](https://github.com/graphql/graphql-js)

## Implementation

Tokenisation is done with [leex](http://erlang.org/doc/man/leex.html) and parsing with [yecc](http://erlang.org/doc/man/yecc.html). Both very useful Erlang tools for parsing. Yecc in particular is used by Elixir itself.

Some resources on using leex and yecc:

* http://relops.com/blog/2014/01/13/leex_and_yecc/
* http://andrealeopardi.com/posts/tokenizing-and-parsing-in-elixir-using-leex-and-yecc/

The Execution logic follows the [GraphQL JS Reference Implementation](https://github.com/graphql/graphql-js) pretty closely, as does the module structure of the project. Not to mention the naming of files and concepts.

If you spot anything that isn't following Elixir conventions though, that's a mistake. Please let us know by opening an issue or a PR and we'll fix it.

## Developers

### Getting Started

Clone the repo and fetch its dependencies:

```
$ git clone https://github.com/graphql-elixir/graphql.git
$ cd graphql
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

If you're planning to implement anything major, please let us know before you get too far so we can make sure your PR will be as mergable as possible. Oh, and don't forget to write tests.

## License

[BSD](https://github.com/graphql-elixir/graphql/blob/master/LICENSE).
