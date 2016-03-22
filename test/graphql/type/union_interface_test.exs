defmodule GraphQL.Lang.Type.UnionInterfaceTest do
  use ExUnit.Case, async: true
  import ExUnit.TestHelpers

  alias GraphQL.Type.String
  alias GraphQL.Type.Object
  alias GraphQL.Type.Boolean
  alias GraphQL.Type.List

  defmodule Dog do
    defstruct name: nil, barks: nil
  end

  defmodule Cat do
    defstruct name: nil, meows: nil
  end

  defmodule Person do
    defstruct name: nil, pets: [], friends: []
  end

  def named_type do
    GraphQL.Type.Interface.new %{
      name: "Named",
      fields:  %{
        name: %{type: %String{}}
      }
    }
  end

  def dog_type do
    %Object{
      name: "Dog",
      interfaces: [named_type],
      fields: %{
       name: %{type: %String{}},
       barks: %{type: %Boolean{}}
      },
      isTypeOf: fn (%Dog{}) -> true; (_) -> false end
    }
  end

  def cat_type do
    %Object{
      name: "Cat",
      interfaces: [named_type],
      fields: %{
       name: %{type: %String{}},
       meows: %{type: %Boolean{}}
      },
      isTypeOf: fn (%Cat{}) -> true; (_) -> false end
    }
  end

  def pet_type do
    GraphQL.Type.Union.new %{
      name: "Pet",
      types: [dog_type, cat_type],
      resolver: fn
        (%Dog{}) -> dog_type
        (%Cat{}) -> cat_type
      end
    }
  end

  def person_type do
    %Object{
      name: "Person",
      interfaces: [named_type],
      fields: %{
        name: %{type: %String{}},
        pets: %{type: %List{ofType: pet_type}},
        friends: %{type: %List{ofType: named_type}},
      },
      isTypeOf: fn (%Person{}) -> true; (_) -> false end
    }
  end

  def schema do
    %GraphQL.Schema{query: person_type}
  end

  def garfield, do: %Cat{name: "Garfield", meows: false}
  def odie, do: %Dog{name: "Odie", barks: true}
  def liz, do: %Person{name: "Liz"}
  def john, do: %Person{name: "John", pets: [ odie, garfield ], friends: [liz, odie]}

  test "can introspect on union and intersection types" do
    query = """
      {
        Named: __type(name: "Named") {
          kind
          name
          fields { name }
          interfaces { name }
          possibleTypes { name }
          enumValues { name }
          inputFields { name }
        }
        Pet: __type(name: "Pet") {
          kind
          name
          fields { name }
          interfaces { name }
          possibleTypes { name }
          enumValues { name }
          inputFields { name }
        }
      }
    """
    assert_execute {query, schema},
      %{"Named" => %{"enumValues" => nil,
                  "fields" => [%{"name" => "name"}],
                  "inputFields" => nil, "interfaces" => nil,
                  "kind" => "INTERFACE", "name" => "Named",
                  "possibleTypes" => [%{"name" => "Cat"},
                   %{"name" => "Dog"}, %{"name" => "Person"}]},
                "Pet" => %{"enumValues" => nil, "fields" => nil,
                  "inputFields" => nil, "interfaces" => nil,
                  "kind" => "UNION", "name" => "Pet",
                  "possibleTypes" => [%{"name" => "Dog"},
                   %{"name" => "Cat"}]}}
  end

  test "executes using union types" do
    # NOTE: This is an *invalid* query, but it should be an *executable* query.
    query = """
     {
        __typename
        name
        pets {
          __typename
          name
          barks
          meows
        }
      }
    """
    assert_execute {query, schema, john},
      %{"__typename" => "Person",
        "name" => "John",
        "pets" => [
          %{"__typename" => "Dog", "barks" => true, "name" => "Odie"},
          %{"__typename" => "Cat", "meows" => false, "name" => "Garfield"}
        ]
      }
  end

  test "executes union types with inline fragments" do
    query = """
      {
        __typename
        name
        pets {
          __typename
          ... on Dog {
            name
            barks
          }
          ... on Cat {
            name
            meows
          }
        }
      }
    """
    assert_execute {query, schema, john},
      %{"__typename" => "Person",
        "name" => "John",
        "pets" => [
          %{"__typename" => "Dog", "barks" => true, "name" => "Odie"},
          %{"__typename" => "Cat", "meows" => false, "name" => "Garfield"}
        ]
      }
  end

  test "executes using interface types" do
    # NOTE: This is an *invalid* query, but it should be an *executable* query.
    query = """
      {
        __typename
        name
        friends {
          __typename
          name
          barks
          meows
        }
      }
    """

    assert_execute {query, schema, john},
      %{"__typename" => "Person",
        "friends" => [
          %{"__typename" => "Person", "name" => "Liz"},
          %{"__typename" => "Dog", "barks" => true, "name" => "Odie"}
        ],
        "name" => "John"
      }
  end

  test "executes types with inline fragments" do
    # This is the valid version of the query in the above test.
    query = """
    {
        __typename
        name
        friends {
          __typename
          name
          ... on Dog {
            barks
          }
          ... on Cat {
            meows
          }
        }
      }
    """
    assert_execute {query, schema, john},
      %{"__typename" => "Person",
        "friends" => [
          %{"__typename" => "Person", "name" => "Liz"},
          %{"__typename" => "Dog", "barks" => true, "name" => "Odie"}
        ],
        "name" => "John"
      }
  end

  test "allows fragment conditions to be abstract types" do
    query = """
      {
        __typename
        name
        pets { ...PetFields }
        friends { ...FriendFields }
      }

      fragment PetFields on Pet {
        __typename
        ... on Dog {
          name
          barks
        }
        ... on Cat {
          name
          meows
        }
      }

      fragment FriendFields on Named {
        __typename
        name
        ... on Dog {
          barks
        }
        ... on Cat {
          meows
        }
      }
      """
      assert_execute {query, schema, john},
        %{"__typename" => "Person",
          "name" => "John",
          "friends" => [
            %{"__typename" => "Person", "name" => "Liz"},
            %{"__typename" => "Dog", "barks" => true, "name" => "Odie"}
          ],
          "pets" => [
            %{"__typename" => "Dog", "barks" => true, "name" => "Odie"},
            %{"__typename" => "Cat", "meows" => false, "name" => "Garfield"}
          ]
        }
  end

  test "gets execution info in resolver" do

  end

end
