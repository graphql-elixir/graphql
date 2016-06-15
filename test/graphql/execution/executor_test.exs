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
    def recursive_schema_query do
      %ObjectType{
        name: "Recursive1",
        fields: fn() -> %{
          id:   %{type: %ID{}, resolve: 1},
          name: %{type: %String{}, resolve: "Mark"},
          b: %{type: TestSchema.recursive_schema_query, resolve: fn() -> %{} end },
          c: %{type: TestSchema.recursive_schema_2, resolve: fn() -> %{} end }
        } end
      }
    end

    def recursive_schema do
      Schema.new(%{
        query: TestSchema.recursive_schema_query
      })
    end

    def recursive_schema_2 do
      %ObjectType{
        name: "Recursive2",
        fields: fn() -> %{
          id:   %{type: %ID{}, resolve: 2},
          name: %{type: %String{}, resolve: "Kate"},
          b: %{type: TestSchema.recursive_schema_query, resolve: fn() -> %{} end }
        } end
      }
    end

    def schema do
      Schema.new(%{
        query: %ObjectType{
          name: "RootQueryType",
          fields: %{
            greeting: %{
              type: %String{},
              args: %{
                name: %{type: %String{}}
              },
              resolve: &greeting/3
            }
          }
        }
      })
    end

    def greeting(_, %{name: name}, _), do: "Hello, #{name}!"
    def greeting(_, _, _), do: "Hello, world!"
  end

  test "basic query execution" do
    {:ok, result} = execute(TestSchema.schema, "{greeting}")
    assert_data(result, %{greeting: "Hello, world!"})
  end

  test "query arguments" do
    {:ok, result} = execute(TestSchema.schema, ~S[{ greeting(name: "Elixir") }])
    assert_data(result, %{greeting: "Hello, Elixir!"})
  end

  test "anonymous fragments are processed" do
    schema = Schema.new(%{
      query: %ObjectType{
        name: "X",
        fields: %{
          id: %{type: %ID{}, resolve: 1},
          name: %{type: %String{}, resolve: "Mark"}
        }
      }
    })

    {:ok, result} = execute(schema, ~S[{id, ...{ name }}])
    assert_data(result, %{id: "1", name: "Mark"})
  end

  test "TypeChecked inline fragments run the correct type" do
    schema = Schema.new(%{
      query: %ObjectType{
        name: "BType",
        fields: %{
          id: %{type: %ID{}, resolve: 1},
          a: %{type: %String{}, resolve: "a"},
          b: %{type: %String{}, resolve: "b"}
        }
      }
    })

    {:ok, result} = execute(schema, ~S[{id, ... on AType { a }, ... on BType { b }}])
    assert_data(result, %{id: "1", b: "b"})
  end

  test "TypeChecked fragments run the correct type" do
    schema = Schema.new(%{
      query: %ObjectType{
        name: "BType",
        fields: %{
          id: %{type: %ID{}, resolve: 1},
          a: %{type: %String{}, resolve: "a"},
          b: %{type: %String{}, resolve: "b"}
        }
      }
    })

    {:ok, result} = execute(schema, ~S[{id, ...spreada ...spreadb} fragment spreadb on BType { b } fragment spreada on AType { a }])
    assert_data(result, %{id: "1", b: "b"})
  end

  test "allow {module, function, args} style of resolve" do
    schema = Schema.new(%{
      query: %ObjectType{
        name: "Q",
        fields: %{
          g: %{type: %String{}, resolve: {TestSchema, :greeting}},
          h: %{type: %String{}, args: %{name: %{type: %String{}}}, resolve: {TestSchema, :greeting, []}}
        }
      }
    })

    {:ok, result} = execute(schema, ~S[query Q {g, h(name:"Joe")}])
    assert_data(result, %{g: "Hello, world!", h: "Hello, Joe!"})
  end

  test "return error when no function matches" do
    schema = %Schema{
      query: %ObjectType{
        name: "RootQueryType",
        fields: %{
          greeting: %{
            type: %String{},
            args: %{
              name: %{type: %String{}}
            },
            resolve: fn(_, %{name: name}, _) -> "Hello #{name}!!" end,
          }
        }
      }
    }

    {_, result } = execute(schema, "query Q{greeting}")
    assert_has_error(result, %{message: "Could not find a resolve function for this query."})
  end

  test "must specify operation name when multiple operations exist" do
    {_, result} = execute(TestSchema.schema, "query a {greeting} query b {greeting} query c {greeting}")
    assert_has_error(result, %{message: "Must provide operation name if query contains multiple operations."})
  end

  test "returns an error when an operation name does not match an operation defined in the query" do
    {_, result} = execute(TestSchema.schema, "query a {greeting}", operation_name: "b")
    assert_has_error(result, %{message: "Must provide an operation name that exists in the query."})
  end

  test "do not include illegal fields in output" do
    {:ok, result} = execute(TestSchema.schema, ~S[query Q {g, h(name:"Joe")}], validate: false)
    assert_data(result, %{})
  end

  test "Quoted fields are available" do
    {:ok, result} = execute(TestSchema.recursive_schema, "{id, b { name, c{ id, name, b { name }}}}")
    assert_data(result, %{id: "1", b: %{name: "Mark", c: %{id: "2", name: "Kate", b: %{name: "Mark"}}}})
  end

  test "simple selection set" do
    schema = Schema.new(%{
      query: %ObjectType{
        name: "PersonQuery",
        fields: %{
          person: %{
            type: %ObjectType{
              name: "Person",
              fields: %{
                id:   %{name: "id",   type: %ID{}, resolve: fn(p) -> p.id   end},
                name: %{name: "name", type: %String{}, resolve: fn(p) -> p.name end},
                age:  %{name: "age",  type: %Int{},    resolve: fn(p) -> p.age  end}
              }
            },
            args: %{
              id: %{type: %ID{}}
            },
            resolve: fn(data, %{id: id}) ->
              Enum.find data, fn(record) -> record.id == id end
            end
          }
        }
      }
    })

    data = [
      %{id: "0", name: "Kate", age: 25},
      %{id: "1", name: "Dave", age: 34},
      %{id: "2", name: "Jeni", age: 45}
    ]

    {:ok, result} = execute(schema,~S[{ person(id: "1") { name } }], root_value: data)
    assert_data(result, %{person: %{name: "Dave"}})

    {:ok, result} = execute(schema,~S[{ person(id: "1") { id name age } }], root_value: data)
    assert_data(result, %{person: %{id: "1", name: "Dave", age: 34}})
  end

  test "use specified query operation" do
    schema = Schema.new(%{
      query: %ObjectType{
        name: "Q",
        fields: %{a: %{ type: %String{}}}
      },
      mutation: %ObjectType{
        name: "M",
        fields: %{b: %{ type: %String{}}}
      }
    })
    data = %{"a" => "A", b: "B"}

    {:ok, result} = execute(schema,~S[query Q { a } mutation M { b }], root_value: data, operation_name: "Q")
    assert_data(result, %{a: "A"})
  end

  test "use specified mutation operation" do
    schema = Schema.new(%{
      query: %ObjectType{
        name: "Q",
        fields: %{a: %{ type: %String{}}}
      },
      mutation: %ObjectType{
        name: "M",
        fields: %{b: %{ type: %String{}}}
      }
    })
    data = %{a: "A", b: "B"}

    {:ok, result} = execute(schema,~S[query Q { a } mutation M { b }], root_value: data, operation_name: "M")
    assert_data(result, %{b: "B"})
  end

  test "lists of things" do
    book = %ObjectType{
      name: "Book",
      fields: %{
        isbn:  %{type: %Int{}},
        title: %{type: %String{}}
      }
    }

    schema = Schema.new(%{
      query: %ObjectType{
        name: "ListsOfThings",
        fields: %{
          numbers: %{
            type: %List{ofType: %Int{}},
            resolve: fn() -> [1, 2] end
          },
          books: %{
            type: %List{ofType: book},
            resolve: fn() ->
              [
                %{title: "A", isbn: "978-3-86680-192-9"},
                %{title: "B", isbn: "978-3-86680-255-1"}
              ]
            end
          }
        }
      }
    })

    {:ok, result} = execute(schema, ~S[{numbers, books {title}}])
    assert_data(result, %{numbers: [1, 2], books: [
      %{title: "A"},
      %{title: "B"}
    ]})
  end

  test "list arguments" do
    schema = Schema.new(%{
      query: %ObjectType{
        name: "ListsAsArguments",
        fields: %{
          numbers: %{
            type: %List{ofType: %Int{}},
            args: %{
              nums: %{type: %List{ofType: %Int{}}}
            },
            resolve: fn(_, %{nums: nums}) -> nums end
          }
        }
      }
    })

    {:ok, result} = execute(schema, "{numbers(nums: [1, 2])}")
    assert_data(result, %{numbers: [1, 2]})
  end

  test "multiple definitions of the same field should be merged" do
    schema = Schema.new(%{
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
            resolve: fn() -> %{id: "1", name: "Dave"} end
          }
        }
      }
    })

    {:ok, result} = execute(schema, "{ person { id name } person { id } }")
    assert_data(result, %{person: %{id: "1", name: "Dave"}})
  end

  test "mutations accept variables " do
    schema = Schema.new(%{
      mutation: %ObjectType{
        name: "PersonMutation",
        fields: %{
          person: %{
            args: %{
              id:   %{name: "id",   type: %ID{}},
              name: %{name: "name", type: %String{}}
            },
            type: %ObjectType{
              name: "Person",
              fields: %{
                id:   %{name: "id",   type: %ID{}},
                name: %{name: "name", type: %String{}}
              }
            },
            resolve: fn(_, args) ->
              %{id: args[:id], name: args[:name]}
            end
          }
        }
      }
    })
    query = ~S[
      mutation hello($id: ID, $name: String){
        person(id: $id, name: $name) {
          id
          name
        }
      }
    ]

    {:ok, result} = execute(
      schema,
      query,
      root_value: %{},
      variable_values: %{"id" => "1", "name" => "Dave"},
      operation_name: "hello"
    )

    assert_data(result, %{person: %{id: "1", name: "Dave"}})
  end

  test "mutations variables are not required " do
    schema = Schema.new(%{
      mutation: %ObjectType{
        name: "PersonMutation",
        fields: %{
          person: %{
            args: %{
              id:   %{name: "id",   type: %ID{}},
              name: %{name: "name", type: %String{}}
            },
            type: %ObjectType{
              name: "Person",
              fields: %{
                id:   %{name: "id",   type: %ID{}},
                name: %{name: "name", type: %String{}}
              }
            },
            resolve: fn(_, args) ->
              %{id: args[:id], name: args[:name]}
            end
          }
        }
      }
    })
    query = ~S[
      mutation hello($id: ID, $name: String){
        person(id: $id, name: $name) {
          id
          name
        }
      }]

    {:ok, result} = execute(
      schema,
      query,
      root_value: %{},
      variable_values: %{"name" => "Dave"},
      operation_name: "hello"
    )

    assert_data(result, %{person: %{id: nil, name: "Dave"}})
  end

  test "mutations accept enums " do
    roleEnum = GraphQL.Type.Enum.new %{
      name: "Role",
      values: %{
        USER: %{value: 2, description: "User"},
        ADMIN: %{value: 3, description: "Admin"}
      }
    }
    schema = Schema.new(%{
      mutation: %ObjectType{
        name: "PersonMutation",
        fields: %{
          person: %{
            args: %{
              id:   %{name: "id",   type: %ID{}},
              name: %{name: "name", type: %String{}},
              role: %{name: "role", type: roleEnum}
            },
            type: %ObjectType{
              name: "Person",
              fields: %{
                id:   %{name: "id",   type: %ID{}},
                name: %{name: "name", type: %String{}},
                role: %{name: "role", type: roleEnum}
              }
            },
            resolve: fn(_, args) ->
              %{id: args[:id], name: args[:name], role: args[:role]}
            end
          }
        }
      }
    })
    query = ~S[
      mutation hello($id: ID, $name: String, $role: Role){
        person(id: $id, name: $name, role: $role) {
          id
          name
          role
        }
      }]

    {:ok, result} = execute(
      schema,
      query,
      root_value: %{},
      variable_values: %{"id" => "1", "name" => "Dave", "role" => "ADMIN"},
      operation_name: "hello"
    )

    assert_data(result, %{person: %{id: "1", name: "Dave", role: "ADMIN"}})
  end

  test "mutations enums are not required" do
    roleEnum = GraphQL.Type.Enum.new %{
      name: "Role",
      values: %{
        USER: %{value: 2, description: "User"},
        ADMIN: %{value: 3, description: "Admin"}
      }
    }
    schema = Schema.new(%{
      mutation: %ObjectType{
        name: "PersonMutation",
        fields: %{
          person: %{
            args: %{
              id:   %{name: "id",   type: %ID{}},
              name: %{name: "name", type: %String{}},
              role: %{name: "role", type: roleEnum}
            },
            type: %ObjectType{
              name: "Person",
              fields: %{
                id:   %{name: "id",   type: %ID{}},
                name: %{name: "name", type: %String{}},
                role: %{name: "role", type: roleEnum}
              }
            },
            resolve: fn(_root, args) ->
              %{id: args[:id], name: args[:name], role: 3}
            end
          }
        }
      }
    })
    query = ~S[
      mutation hello($id: ID, $name: String){
        person(id: $id, name: $name) {
          id
          name
          role
        }
      }]

    {:ok, result} = execute(
      schema,
      query,
      root_value: %{},
      variable_values: %{"id" => "1", "name" => "Dave"},
      operation_name: "hello"
    )

    assert_data(result, %{person: %{id: "1", name: "Dave", role: "ADMIN"}})
  end

  test "mutations enums are not required in variables" do
    roleEnum = GraphQL.Type.Enum.new %{
      name: "Role",
      values: %{
        USER: %{value: 2, description: "User"},
        ADMIN: %{value: 3, description: "Admin"}
      }
    }
    schema = Schema.new(%{
      mutation: %ObjectType{
        name: "PersonMutation",
        fields: %{
          person: %{
            args: %{
              id:   %{name: "id",   type: %ID{}},
              name: %{name: "name", type: %String{}},
              role: %{name: "role", type: roleEnum}
            },
            type: %ObjectType{
              name: "Person",
              fields: %{
                id:   %{name: "id",   type: %ID{}},
                name: %{name: "name", type: %String{}},
                role: %{name: "role", type: roleEnum}
              }
            },
            resolve: fn(_, args) ->
              %{id: args[:id], name: args[:name], role: 3}
            end
          }
        }
      }
    })
    query = ~S[
      mutation hello($id: ID, $name: String, $role: Role){
        person(id: $id, name: $name, role: $role) {
          id
          name
          role
        }
      }]

    {:ok, result} = execute(
      schema,
      query,
      root_value: %{},
      variable_values: %{"id" => "1", "name" => "Dave"},
      operation_name: "hello"
    )

    assert_data(result, %{person: %{id: "1", name: "Dave", role: "ADMIN"}})
  end

  test "mutations enums will use default value when not passed in" do
    roleEnum = GraphQL.Type.Enum.new %{
      name: "Role",
      values: %{
        USER: %{value: 2, description: "User"},
        ADMIN: %{value: 3, description: "Admin"}
      }
    }
    schema = Schema.new(%{
      mutation: %ObjectType{
        name: "PersonMutation",
        fields: %{
          person: %{
            args: %{
              id:   %{name: "id",   type: %ID{}},
              name: %{name: "name", type: %String{}},
              role: %{name: "role", type: roleEnum}
            },
            type: %ObjectType{
              name: "Person",
              fields: %{
                id:   %{name: "id",   type: %ID{}},
                name: %{name: "name", type: %String{}},
                role: %{name: "role", type: roleEnum}
              }
            },
            resolve: fn(_, args) ->
              %{id: args[:id], name: args[:name], role: args[:role]}
            end
          }
        }
      }
    })
    query = ~S[
      mutation hello($id: ID, $name: String = "Bob", $role: Role = USER){
        person(id: $id, name: $name, role: $role) {
          id
          name
          role
        }
      }]

    {:ok, result} = execute(
      schema,
      query,
      root_value: %{},
      variable_values: %{"id" => "1", "name" => "Dave"},
      operation_name: "hello"
    )

    assert_data(result, %{person: %{id: "1", name: "Dave", role: "USER"}})
  end

  test "mutations will use default value when not passed in" do
    schema = Schema.new(%{
      mutation: %ObjectType{
        name: "PersonMutation",
        fields: %{
          person: %{
            args: %{
              id:   %{name: "id",   type: %ID{}},
              name: %{name: "name", type: %String{}}
            },
            type: %ObjectType{
              name: "Person",
              fields: %{
                id:   %{name: "id",   type: %ID{}},
                name: %{name: "name", type: %String{}}
              }
            },
            resolve: fn(_, args) ->
              %{id: args[:id], name: args[:name]}
            end
          }
        }
      }
    })
    query = ~S[
      mutation hello($id: ID, $name: String = "Dave"){
        person(id: $id, name: $name, role: $role) {
          id
          name
        }
      }]

    {:ok, result} = execute(
      schema,
      query,
      root_value: %{},
      variable_values: %{"id" => "1"},
      operation_name: "hello"
    )

    assert_data(result, %{person: %{id: "1", name: "Dave"}})
  end
end
