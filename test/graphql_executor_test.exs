
defmodule GraphqlExecutorTest do
  use ExUnit.Case, async: true

  def assert_execute(query, schema, data, expected_output) do
    assert GraphQL.execute(query, schema, data) == expected_output
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
              args: %{
                name: %{ type: "String" }
              },
              resolve: &greeting/3,
            }
          ]
        }
      }
    end

    def greeting(_, %{name: name}, _), do: "Hello, #{name}!"
    def greeting(_, _, _), do: "Hello, world!"
  end

  test "basic query execution" do
    query = "{ greeting }"
    {:ok, doc} = GraphQL.parse query
    assert GraphQL.execute(TestSchema.schema, doc) == {:ok, %{"greeting" => "Hello, world!"}}
  end

  test "query arguments" do
    query = "{ greeting(name: \"Elixir\") }"
    {:ok, doc} = GraphQL.parse query
    assert GraphQL.execute(TestSchema.schema, doc) == {:ok, %{"greeting" => "Hello, Elixir!"}}
  end

  # test "simple selection set" do
  #   schema = %GraphQL.Schema{
  #     query: %GraphQL.ObjectType{
  #       name: "Q",
  #       fields: [
  #         %GraphQL.FieldDefinition{name: "id",   type: "Int",    resolve: fn(p) -> p.id   end},
  #         %GraphQL.FieldDefinition{name: "name", type: "String", resolve: fn(p) -> p.name end},
  #         %GraphQL.FieldDefinition{name: "age",  type: "Int",    resolve: fn(p) -> p.age  end}
  #       ]
  #     }
  #   }
  #
  #   data = [
  #     %{id: 0, name: 'Kate', age: 25},
  #     %{id: 1, name: 'Dave', age: 34},
  #     %{id: 2, name: 'Jeni', age: 45}
  #   ]
  #
  #   {:ok, doc} = GraphQL.parse("query Q { Person(id:1) { name } }")
  #   assert GraphQL.execute(schema, doc, nil, nil, "Q") == {:ok, %{name: "Dave"}}
  # end

  # it('uses the query schema for queries', async () => {
  #   var doc = `query Q { a } mutation M { c } subscription S { a }`;
  #   var data = { a: 'b', c: 'd' };
  #   var ast = parse(doc);
  #   var schema = new GraphQLSchema({
  #     query: new GraphQLObjectType({
  #       name: 'Q',
  #       fields: {
  #         a: { type: GraphQLString },
  #       }
  #     }),
  #     mutation: new GraphQLObjectType({
  #       name: 'M',
  #       fields: {
  #         c: { type: GraphQLString },
  #       }
  #     }),
  #     subscription: new GraphQLObjectType({
  #       name: 'S',
  #       fields: {
  #         a: { type: GraphQLString },
  #       }
  #     })
  #   });
  #
  #   var queryResult = await execute(schema, ast, data, {}, 'Q');
  #
  #   expect(queryResult).to.deep.equal({ data: { a: 'b' } });
  # });

end
