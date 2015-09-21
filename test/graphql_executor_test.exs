
defmodule GraphqlExecutorTest do
  use ExUnit.Case, async: true

  defmodule Person do
    defstruct name: "John", age: 27, id: 0
  end

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

  test "hello world" do
    schema = %GraphQL.Schema{
      query: %GraphQL.ObjectType{
        name: "RootQueryType",
        fields: [
          # %GraphQL.FieldDefinition{
          #   name: "planet",
          #   type: "String",
          #   resolve: "mars"
          # },
          %GraphQL.FieldDefinition{
            name: "hello",
            type: "String",
            resolve: "world"
          }
        ]
      }
    }
    query = "{ hello }"
    assert GraphQL.execute(schema, query) == [data: [hello: "world"]]
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
