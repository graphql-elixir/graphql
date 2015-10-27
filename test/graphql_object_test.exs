defmodule GraphQL.ObjectTest do
  use ExUnit.Case
  alias GraphQL.Object

  defmodule Person do
    use GraphQL.Object

    field :name
    field :age
  end

  test "an GraphQL object behaves like a struct" do
    p = %Person{name: "James", age: 28}
    assert p.name == "James"
    assert p.age == 28
  end
end
