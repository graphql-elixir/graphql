defmodule GraphQL.ObjectTest do
  use ExUnit.Case

  defmodule Person do
    use GraphQL.Object

    field :name
    field :age
    field :sex
  end

  # defmodule Employee do
  #   use GraphQL.Object, deriving: Person

  #   field :salary
  # end

  test "a GraphQL object behaves like a struct" do
    p = %Person{name: "James", age: 28}
    assert p.name == "James"
    assert p.age == 28
    assert p.sex == nil
  end

  test "a GraphQL object contains a meta module" do
    assert Person.Meta.fields == [sex: [], age: [], name: []]
  end

  # test "a GraphQL object can inherit fields from another object" do
  #   e = %Employee{name: "Anna", age: 32, sex: "F", salary: 175000}
  #   assert e.name == "Anna"
  #   assert e.age == 32
  #   assert e.salary == 175000
  #   assert e.sex == "F"
  #   assert Employee.Meta.fields == [salary: [], sex: [], age: [], name: []]
  # end
end
