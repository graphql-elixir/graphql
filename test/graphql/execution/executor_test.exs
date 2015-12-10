
defmodule GraphQL.Execution.Executor.ExecutorTest do
  use ExUnit.Case, async: true

  alias GraphQL.Lang.Parser
  alias GraphQL.Execution.Executor

  def assert_execute({query, schema}, expected_output) do
    {:ok, doc} = Parser.parse(query)
    assert Executor.execute(schema, doc) == {:ok, expected_output}
  end

  def assert_execute({query, schema, data}, expected_output) do
    {:ok, doc} = Parser.parse(query)
    assert Executor.execute(schema, doc, data) == {:ok, expected_output}
  end

  defmodule TestSchema do
    def schema do
      %GraphQL.Schema{
        query: %GraphQL.ObjectType{
          name: "RootQueryType",
          fields: %{
            greeting: %{
              type: "String",
              args: %{
                name: %{ type: "String" }
              },
              resolve: &greeting/3,
            }
          }
        }
      }
    end

    def greeting(_, %{name: name}, _), do: "Hello, #{name}!"
    def greeting(_, _, _), do: "Hello, world!"
  end

  test "basic query execution" do
    assert_execute {"{ greeting }", TestSchema.schema}, %{"greeting" => "Hello, world!"}
  end

  # test "error can't find field" do
  #   assert_execute {"{ a }", TestSchema.schema}, %{error: "can't find field..."}
  # end

  test "query arguments" do
    assert_execute {~S[{ greeting(name: "Elixir") }], TestSchema.schema}, %{"greeting" => "Hello, Elixir!"}
  end

  test "allow {module, function, args} style of resolve" do
    schema = %GraphQL.Schema{
      query: %GraphQL.ObjectType{
        name: "Q",
        fields: %{
          g: %{ type: "String", resolve: {TestSchema, :greeting} },
          h: %{ type: "String", args: %{name: %{type: "String" }}, resolve: {TestSchema, :greeting, []} }
        }
      }
    }
    assert_execute {~S[query Q {g, h(name:"Joe")}], schema}, %{"g" => "Hello, world!", "h" => "Hello, Joe!"}
  end

  test "simple selection set" do
    schema = %GraphQL.Schema{
      query: %GraphQL.ObjectType{
        name: "PersonQuery",
        fields: %{
          person: %{
            type: %GraphQL.ObjectType{
              name: "Person",
              fields: %{
                id:   %{name: "id",   type: "String", resolve: fn(p, _, _) -> p.id   end},
                name: %{name: "name", type: "String", resolve: fn(p, _, _) -> p.name end},
                age:  %{name: "age",  type: "Int",    resolve: fn(p, _, _) -> p.age  end}
              }
            },
            args: %{
              id: %{ type: "String" }
            },
            resolve: fn(data, %{id: id}, _) ->
              Enum.find data, fn(record) -> record.id == id end
            end
          }
        }
      }
    }

    data = [
      %{id: "0", name: "Kate", age: 25},
      %{id: "1", name: "Dave", age: 34},
      %{id: "2", name: "Jeni", age: 45}
    ]

    assert_execute {~S[{ person(id: "1") { name } }], schema, data}, %{"person" => %{"name" => "Dave"}}
    assert_execute {~S[{ person(id: "1") { id name age } }], schema, data}, %{"person" => %{"id" => "1", "name" => "Dave", "age" => 34}}
  end

  test "use specified query operation" do
    schema = %GraphQL.Schema{
      query: %GraphQL.ObjectType{
        name: "Q",
        fields: %{a: %{ type: "String"}}
      },
      mutation: %GraphQL.ObjectType{
        name: "M",
        fields: %{b: %{ type: "String"}}
      }
    }
    data = %{"a" => "A", "b" => "B"}
    {:ok, doc} = Parser.parse "query Q { a } mutation M { b }"
    assert Executor.execute(schema, doc, data, nil, "Q") == {:ok, %{"a" => "A"}}
  end

  test "use specified mutation operation" do
    schema = %GraphQL.Schema{
      query: %GraphQL.ObjectType{
        name: "Q",
        fields: %{a: %{ type: "String"}}
      },
      mutation: %GraphQL.ObjectType{
        name: "M",
        fields: %{b: %{ type: "String"}}
      }
    }
    data = %{"a" => "A", "b" => "B"}
    {:ok, doc} = Parser.parse "query Q { a } mutation M { b }"
    assert Executor.execute(schema, doc, data, nil, "M") == {:ok, %{"b" => "B"}}
  end

  test "lists of things" do
    book = %GraphQL.ObjectType{
      name: "Book",
      fields: %{
        isbn:  %{ type: "Int",    resolve: fn(p, _, _) -> p.isbn end},
        title: %{ type: "String", resolve: fn(p, _, _) -> p.title end}
      }
    }

    schema = %GraphQL.Schema{
      query: %GraphQL.ObjectType{
        name: "ListsOfThings",
        fields: %{
          numbers: %{
            type: %GraphQL.List{of_type: "Int"},
            resolve: fn(_, _, _) -> [1, 2] end
          },
          books: %{
            type: %GraphQL.List{of_type: book},
            resolve: fn(_, _, _) ->
              [
                %{title: "A", isbn: "978-3-86680-192-9"},
                %{title: "B", isbn: "978-3-86680-255-1"}
              ]
            end
          }
        }
      }
    }

    assert_execute {"{numbers, books {title}}", schema},
      %{
        "numbers" => [1, 2],
        "books" => [
          %{"title" => "A"},
          %{"title" => "B"}
        ]
      }
  end
end
