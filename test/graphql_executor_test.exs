
defmodule GraphqlExecutorTest do
  use ExUnit.Case, async: true

  def assert_execute(query, schema, data_store, expected_output) do
    assert GraphQL.execute(query, schema, data_store) == expected_output
  end

  # var schema = new GraphQLSchema({
  #   query: new GraphQLObjectType({
  #     name: 'RootQueryType',
  #     fields: {
  #       hello: {
  #         type: GraphQLString,
  #         resolve() {
  #           return 'world';
  #         }
  #       }
  #     }
  #   })
  # });

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
      
  test "query arguments" do
    query = "{ greeting }"
    assert GraphQL.execute(TestSchema.schema, query) == [data: [greeting: "Hello, world!"]]

    query = "{ greeting(name: \"Elixir\") }"
    assert GraphQL.execute(TestSchema.schema, query) == [data: [greeting: "Hello, Elixir!"]]
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
