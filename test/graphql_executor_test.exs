
defmodule GraphqlExecutorTest do
  use ExUnit.Case, async: true

  defmodule Person do
    defstruct name: "John", age: 27, id: 0
  end

  def assert_execute(query, schema, data, expected_output) do
    assert GraphQL.execute(query, schema, data) == expected_output
  end

  test "simple selection set" do

    data_store = [
      %Person{id: 0, name: 'Kate', age: '25'},
      %Person{id: 1, name: '', age: '34'},
      %Person{id: 2, name: 'Jeni', age: '45'}
    ]

    assert_execute '{ name }', 'type Person { name: String }', data_store,
      ~S({"name": "Dave"})
  end
end
