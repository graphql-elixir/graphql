
defmodule GraphqlExecutorTest do
  use ExUnit.Case, async: true

  def assert_execute(query, schema, data_store, expected_output) do
    assert GraphQL.execute(query, schema, data_store) == expected_output
  end

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
            },
            %GraphQL.ObjectType{
              name: "person",
              fields: [
                %GraphQL.FieldDefinition{
                  name: "name",
                  type: "String",
                  resolve: &person_name/1
                }
              ]
            }
          ]
        }
      }
    end

    def greeting(name: name), do: "Hello, #{name}!"
    def greeting(_), do: greeting(name: "world")

    def person_name(_), do: "Nick"
  end

  test "basic query execution" do
    query = "{ greeting }"
    assert GraphQL.execute(TestSchema.schema, query) == {:ok, %{greeting: "Hello, world!"}}
  end

  test "query arguments" do
    query = "{ greeting(name: \"Elixir\") }"
    assert GraphQL.execute(TestSchema.schema, query) == {:ok, %{greeting: "Hello, Elixir!"}}
  end

  test "query object type fields" do
    query = "{ greeting, person { name } }"
    assert GraphQL.execute(TestSchema.schema, query) == {:ok, %{greeting: "Hello, world!", person: %{name: "Nick"} }}
  end

  test "query undefined field" do
    query = "{ undefined }"
    assert GraphQL.execute(TestSchema.schema, query) == {:ok, %{}}
  end

  test "query nested undefined field" do 
    query = "{ greeting, person { title } }"
    assert GraphQL.execute(TestSchema.schema, query) == {:ok, %{greeting: "Hello, world!"}}
  end



  # test "simple selection set" do
  #
  #   data_store = [
  #     %Person{id: 0, name: 'Kate', age: '25'},
  #     %Person{id: 1, name: 'Dave', age: '34'},
  #     %Person{id: 2, name: 'Jeni', age: '45'}
  #   ]
  #
  #   assert_execute 'query dave { Person(id:1) { name } }', schema, data_store,
  #     ~S({"name": "Dave"})
  # end
end
