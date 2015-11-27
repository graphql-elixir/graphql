
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
          fields: %{
            greeting: %GraphQL.FieldDefinition{
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
    query = "{ greeting }"
    {:ok, doc} = GraphQL.parse query
    assert GraphQL.execute(TestSchema.schema, doc) == {:ok, %{"greeting" => "Hello, world!"}}
  end

  test "query arguments" do
    query = "{ greeting(name: \"Elixir\") }"
    {:ok, doc} = GraphQL.parse query
    assert GraphQL.execute(TestSchema.schema, doc) == {:ok, %{"greeting" => "Hello, Elixir!"}}
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
                id:   %GraphQL.FieldDefinition{name: "id",   type: "String", resolve: fn(p, _, _) -> p.id   end},
                name: %GraphQL.FieldDefinition{name: "name", type: "String", resolve: fn(p, _, _) -> p.name end},
                age:  %GraphQL.FieldDefinition{name: "age",  type: "Int",    resolve: fn(p, _, _) -> p.age  end}
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

    {:ok, doc} = GraphQL.parse ~S[{ person(id: "1") { name } }]
    assert GraphQL.execute(schema, doc, data) == {:ok, %{"person" => %{"name" => "Dave"}}}
  end

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
