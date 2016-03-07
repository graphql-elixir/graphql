
defmodule GraphQL.Execution.Executor.ExecutorTest do
  use ExUnit.Case, async: true

  import ExUnit.TestHelpers

  alias GraphQL.Schema
  alias GraphQL.Type.ObjectType
  alias GraphQL.Type.List
  alias GraphQL.Type.ID
  alias GraphQL.Type.String
  alias GraphQL.Type.Int

  defmodule TestSchema do
    def recursive_schema do
      %Schema{
        query: %ObjectType{
          name: "Recursive1",
          fields: fn() -> %{
            id:   %{type: %ID{}, resolve: 1},
            name: %{type: %String{}, resolve: "Mark"},
            b: %{type: TestSchema.recursive_schema.query, resolve: fn(_,_,_) -> %{} end },
            c: %{type: TestSchema.recursive_schema_2, resolve: fn(_,_,_) -> %{} end }
          } end
        }
      }
    end

    def recursive_schema_2 do
      %ObjectType{
        name: "Recursive2",
        fields: fn() -> %{
          id:   %{type: %ID{}, resolve: 2},
          name: %{type: %String{}, resolve: "Kate"},
          b: %{type: TestSchema.recursive_schema.query, resolve: fn(_,_,_) -> %{} end }
        } end
      }
    end

    def schema do
      %Schema{
        query: %ObjectType{
          name: "RootQueryType",
          fields: %{
            greeting: %{
              type: %String{},
              args: %{
                name: %{type: %String{}}
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
    assert_execute {"{ greeting }", TestSchema.schema}, %{greeting: "Hello, world!"}
  end

  test "query arguments" do
    assert_execute {~S[{ greeting(name: "Elixir") }], TestSchema.schema}, %{greeting: "Hello, Elixir!"}
  end

  test "anonymous fragments are processed" do
    schema = %Schema{
      query: %ObjectType{
        name: "X",
        fields: %{
          id: %{type: %ID{}, resolve: 1},
          name: %{type: %String{}, resolve: "Mark"}
        }
      }
    }
    assert_execute {"{id, ...{ name }}", schema}, %{id: "1", name: "Mark"}
  end

  test "TypeChecked inline fragments run the correct type" do
    schema = %Schema{
      query: %ObjectType{
        name: "BType",
        fields: %{
          id: %{type: %ID{}, resolve: 1},
          a: %{type: %String{}, resolve: "a"},
          b: %{type: %String{}, resolve: "b"}
        }
      }
    }
    assert_execute {"{id, ... on AType { a }, ... on BType { b }}", schema}, %{id: "1", b: "b"}
  end

  test "TypeChecked fragments run the correct type" do
    schema = %Schema{
      query: %ObjectType{
        name: "BType",
        fields: %{
          id: %{type: %ID{}, resolve: 1},
          a: %{type: %String{}, resolve: "a"},
          b: %{type: %String{}, resolve: "b"}
        }
      }
    }
    assert_execute {"{id, ...spreada ...spreadb} fragment spreadb on BType { b } fragment spreada on AType { a }", schema}, %{id: "1", b: "b"}
  end

  test "allow {module, function, args} style of resolve" do
    schema = %Schema{
      query: %ObjectType{
        name: "Q",
        fields: %{
          g: %{type: %String{}, resolve: {TestSchema, :greeting}},
          h: %{type: %String{}, args: %{name: %{type: %String{}}}, resolve: {TestSchema, :greeting, []}}
        }
      }
    }
    assert_execute {~S[query Q {g, h(name:"Joe")}], schema}, %{g: "Hello, world!", h: "Hello, Joe!"}
  end

  test "must specify operation name when multiple operations exist" do
    assert_execute_error {"query a {a} query b {b} query c {c}", TestSchema.schema},
      [%{message: "Must provide operation name if query contains multiple operations."}]
  end

  test "do not include illegal fields in output" do
    assert_execute {"{ a }", TestSchema.schema}, %{}
  end

  test "Quoted fields are available" do
    assert_execute({"{id, b { name, c{ id, name, b { name }}}}", TestSchema.recursive_schema},
        %{id: "1", b: %{name: "Mark", c: %{id: "2", name: "Kate", b: %{name: "Mark"}}}})
  end

  test "simple selection set" do
    schema = %Schema{
      query: %ObjectType{
        name: "PersonQuery",
        fields: %{
          person: %{
            type: %ObjectType{
              name: "Person",
              fields: %{
                id:   %{name: "id",   type: %ID{}, resolve: fn(p, _, _) -> p.id   end},
                name: %{name: "name", type: %String{}, resolve: fn(p, _, _) -> p.name end},
                age:  %{name: "age",  type: %Int{},    resolve: fn(p, _, _) -> p.age  end}
              }
            },
            args: %{
              id: %{type: %ID{}}
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

    assert_execute {~S[{ person(id: "1") { name } }], schema, data}, %{person: %{name: "Dave"}}
    assert_execute {~S[{ person(id: "1") { id name age } }], schema, data}, %{person: %{id: "1", name: "Dave", age: 34}}
  end

  test "use specified query operation" do
    schema = %Schema{
      query: %ObjectType{
        name: "Q",
        fields: %{a: %{ type: %String{}}}
      },
      mutation: %ObjectType{
        name: "M",
        fields: %{b: %{ type: %String{}}}
      }
    }
    data = %{"a" => "A", b: "B"}
    assert_execute {"query Q { a } mutation M { b }", schema, data, nil, "Q"}, %{a: "A"}
  end

  test "use specified mutation operation" do
    schema = %Schema{
      query: %ObjectType{
        name: "Q",
        fields: %{a: %{ type: %String{}}}
      },
      mutation: %ObjectType{
        name: "M",
        fields: %{b: %{ type: %String{}}}
      }
    }
    data = %{a: "A", b: "B"}
    assert_execute {"query Q { a } mutation M { b }", schema, data, nil, "M"}, %{b: "B"}
  end

  test "lists of things" do
    book = %ObjectType{
      name: "Book",
      fields: %{
        isbn:  %{type: %Int{}},
        title: %{type: %String{}}
      }
    }

    schema = %Schema{
      query: %ObjectType{
        name: "ListsOfThings",
        fields: %{
          numbers: %{
            type: %List{ofType: %Int{}},
            resolve: fn(_, _, _) -> [1, 2] end
          },
          books: %{
            type: %List{ofType: book},
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
      %{numbers: [1, 2], books: [
        %{title: "A"},
        %{title: "B"}
      ]}
  end

  test "list arguments" do
    schema = %Schema{
      query: %ObjectType{
        name: "ListsAsArguments",
        fields: %{
          numbers: %{
            type: %List{ofType: %Int{}},
            args: %{
              nums: %{type: %List{ofType: %Int{}}}
            },
            resolve: fn(_, %{nums: nums}, _) -> nums end
          }
        }
      }
    }

    assert_execute {"{numbers(nums: [1, 2])}", schema}, %{numbers: [1, 2]}
  end

  test "multiple definitions of the same field should be merged" do
    schema = %Schema{
      query: %ObjectType{
        name: "PersonQuery",
        fields: %{
          person: %{
            type: %ObjectType{
              name: "Person",
              fields: %{
                id:   %{name: "id",   type: %ID{}},
                name: %{name: "name", type: %String{}}
              }
            },
            resolve: fn(_, _, _) -> %{id: "1", name: "Dave"} end
          }
        }
      }
    }

    assert_execute {~S[{ person { id name } person { id } }], schema}, %{person: %{id: "1", name: "Dave"}}
  end
end
