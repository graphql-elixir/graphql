Code.require_file "../support/star_wars/data.exs", __DIR__
Code.require_file "../support/star_wars/schema.exs", __DIR__

defmodule GraphQL.StarWars.IntrospectionTest do
  use ExUnit.Case, async: true
  import ExUnit.TestHelpers

  test "Allows querying the schema for types" do
    query = """
      query IntrospectionTypeQuery {
          __schema {
            types {
              name
            }
          }
        }
    """
    assert_execute {query, StarWars.Schema.schema}, %{
      __schema: %{
        types: Enum.map(~w(Boolean Character Droid Episode Human Query String __Directive __EnumValue __Field __InputValue __Schema __Type __TypeKind), fn(t) -> %{name: t} end)
      }
    }
  end

  test "Allows querying the schema for query type" do
    query = """
     query IntrospectionQueryTypeQuery {
      __schema {
        queryType {
          name
        }
      }
    }
    """
    assert_execute {query, StarWars.Schema.schema}, %{
      __schema: %{queryType: %{name: "Query"}}
    }
  end

  test "Allows querying the schema for a specific type" do
    query = """
      query IntrospectionDroidTypeQuery {
        __type(name: "Droid") {
          name
        }
      }
    """
    assert_execute {query, StarWars.Schema.schema}, %{
      __type: %{name: "Droid"}
    }
  end

  test "Allows querying the schema for an object kind" do
    query = """
      query IntrospectionDroidKindQuery {
        __type(name: "Droid") {
          name
          kind
        }
      }
    """
    assert_execute {query, StarWars.Schema.schema}, %{
      __type: %{name: "Droid", kind: "OBJECT"}
    }
  end

  test "Allows querying the schema for an interface kind" do
    query = """
      query IntrospectionCharacterKindQuery {
        __type(name: "Character") {
          name
          kind
        }
      }
    """
    assert_execute {query, StarWars.Schema.schema}, %{
      __type: %{name: "Character", kind: "INTERFACE"}
    }
  end

  test "Allows querying the schema for object fields" do
    query = """
      query IntrospectionDroidFieldsQuery {
        __type(name: "Droid") {
          name
          fields {
            name
            type {
              name
              kind
            }
          }
        }
      }
    """
    assert_execute {query, StarWars.Schema.schema}, %{
      __type: %{
        fields: [
          %{name: "appears_in", type: %{kind: "LIST", name: nil}},
          %{name: "friends", type: %{kind: "LIST", name: nil}},
          %{name: "id", type: %{kind: "NON_NULL", name: nil}},
          %{name: "name", type: %{kind: "SCALAR", name: "String"}},
          %{name: "primary_function", type: %{kind: "SCALAR", name: "String"}}
        ],
        name: "Droid"
      }
    }
  end

  test "Allows querying the schema for nested object fields" do
    query = """
      query IntrospectionDroidNestedFieldsQuery {
        __type(name: "Droid") {
          name
          fields {
            name
            type {
              name
              kind
              ofType {
                name
                kind
              }
            }
          }
        }
      }
    """
    assert_execute {query, StarWars.Schema.schema}, %{
      __type: %{
        name: "Droid",
        fields: [
          %{
            name: "appears_in",
            type: %{kind: "LIST", name: nil, ofType: %{kind: "ENUM", name: "Episode"}}
          },
          %{
            name: "friends",
            type: %{kind: "LIST", name: nil, ofType: %{kind: "INTERFACE", name: "Character"}}
          },
          %{
            name: "id",
            type: %{kind: "NON_NULL", name: nil, ofType: %{kind: "SCALAR", name: "String"}}
          },
          %{
            name: "name",
            type: %{kind: "SCALAR", name: "String", ofType: nil}
          },
          %{
            name: "primary_function",
            type: %{kind: "SCALAR", name: "String", ofType: nil}
          }
        ]
      }
    }
  end

  @tag :skip # we need to add default_value before this will be complete
  test "Allows querying the schema for field args" do
    query = """
      query IntrospectionQueryTypeQuery {
        __schema {
          queryType {
            fields {
              name
              args {
                name
                description
                type {
                  name
                  kind
                  ofType {
                    name
                    kind
                  }
                }
                default_value
              }
            }
          }
        }
      }
    """
    assert_execute {query, StarWars.Schema.schema}, %{}
  end

  test "Allows querying the schema for documentation" do
    query = """
      query IntrospectionDroidDescriptionQuery {
        __type(name: "Droid") {
          name
          description
        }
      }
    """
    assert_execute {query, StarWars.Schema.schema}, %{
      __type: %{description: "A mechanical creature in the Star Wars universe", name: "Droid"}
    }
  end

  test "Can run the full introspection query" do
    assert_execute {GraphQL.Type.Introspection.query, StarWars.Schema.schema}, %{
      "__schema" => %{"directives" => nil, "mutationType" => nil, "queryType" => %{"name" => "Query"}, "subscriptionType" => nil,
      "types" => [%{"description" => "The `Boolean` scalar type represents `true` or `false`.\n", "enumValues" => nil, "fields" => nil, "inputFields" => nil, "interfaces" => nil, "kind" => "SCALAR", "name" => "Boolean", "possibleTypes" => nil},
       %{"description" => "A character in the Star Wars Trilogy", "enumValues" => nil,
         "fields" => [%{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "appears_in", "type" => %{"kind" => "LIST", "name" => nil, "ofType" => %{"kind" => "ENUM", "name" => "Episode", "ofType" => nil}}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "friends", "type" => %{"kind" => "LIST", "name" => nil, "ofType" => %{"kind" => "INTERFACE", "name" => "Character", "ofType" => nil}}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "id", "type" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "name", "type" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}}], "inputFields" => nil, "interfaces" => nil, "kind" => "INTERFACE", "name" => "Character",
         "possibleTypes" => [%{"kind" => "OBJECT", "name" => "Droid", "ofType" => nil}, %{"kind" => "OBJECT", "name" => "Human", "ofType" => nil}]},
       %{"description" => "A mechanical creature in the Star Wars universe", "enumValues" => nil,
         "fields" => [%{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "appears_in", "type" => %{"kind" => "LIST", "name" => nil, "ofType" => %{"kind" => "ENUM", "name" => "Episode", "ofType" => nil}}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "friends", "type" => %{"kind" => "LIST", "name" => nil, "ofType" => %{"kind" => "INTERFACE", "name" => "Character", "ofType" => nil}}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "id", "type" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "name", "type" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "primary_function", "type" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}}], "inputFields" => nil,
         "interfaces" => [%{"kind" => "INTERFACE", "name" => "Character", "ofType" => nil}], "kind" => "OBJECT", "name" => "Droid", "possibleTypes" => nil},
       %{"description" => "One of the films in the Star Wars Trilogy",
         "enumValues" => [%{"deprecationReason" => nil, "description" => "Released in 1980", "isDeprecated" => nil, "name" => "EMPIRE"}, %{"deprecationReason" => nil, "description" => "Released in 1983", "isDeprecated" => nil, "name" => "JEDI"},
          %{"deprecationReason" => nil, "description" => "Released in 1977", "isDeprecated" => nil, "name" => "NEWHOPE"}], "fields" => nil, "inputFields" => nil, "interfaces" => nil, "kind" => "ENUM", "name" => "Episode", "possibleTypes" => nil},
       %{"description" => "A humanoid creature in the Star Wars universe", "enumValues" => nil,
         "fields" => [%{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "appears_in", "type" => %{"kind" => "LIST", "name" => nil, "ofType" => %{"kind" => "ENUM", "name" => "Episode", "ofType" => nil}}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "friends", "type" => %{"kind" => "LIST", "name" => nil, "ofType" => %{"kind" => "INTERFACE", "name" => "Character", "ofType" => nil}}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "home_planet", "type" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "id", "type" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "name", "type" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}}], "inputFields" => nil, "interfaces" => [%{"kind" => "INTERFACE", "name" => "Character", "ofType" => nil}],
         "kind" => "OBJECT", "name" => "Human", "possibleTypes" => nil},
       %{"description" => "", "enumValues" => nil,
         "fields" => [%{"args" => [%{"defaultValue" => nil, "description" => "id of the droid", "name" => "id", "type" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}}}], "deprecationReason" => nil, "description" => nil,
            "isDeprecated" => nil, "name" => "droid", "type" => %{"kind" => "OBJECT", "name" => "Droid", "ofType" => nil}},
          %{"args" => [%{"defaultValue" => nil, "description" => "If omitted, returns the hero of the whole saga. If provided, returns the hero of that particular episode", "name" => "episode", "type" => %{"kind" => "ENUM", "name" => "Episode", "ofType" => nil}}], "deprecationReason" => nil,
            "description" => nil, "isDeprecated" => nil, "name" => "hero", "type" => %{"kind" => "INTERFACE", "name" => "Character", "ofType" => nil}},
          %{"args" => [%{"defaultValue" => nil, "description" => "id of the human", "name" => "id", "type" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}}}], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil,
            "name" => "human", "type" => %{"kind" => "OBJECT", "name" => "Human", "ofType" => nil}}], "inputFields" => nil, "interfaces" => [], "kind" => "OBJECT", "name" => "Query", "possibleTypes" => nil},
       %{"description" => "The `String` scalar type represents textual data, represented as UTF-8\ncharacter sequences. The String type is most often used by GraphQL to\nrepresent free-form human-readable text.\n", "enumValues" => nil, "fields" => nil, "inputFields" => nil, "interfaces" => nil,
         "kind" => "SCALAR", "name" => "String", "possibleTypes" => nil},
       %{"description" => "A Directive provides a way to describe alternate runtime execution and\ntype validation behavior in a GraphQL document.\n\nIn some cases, you need to provide options to alter GraphQL’s\nexecution behavior in ways field arguments will not suffice, such as\nconditionally including or skipping a field. Directives provide this by\ndescribing additional information to the executor\n",
         "enumValues" => nil,
         "fields" => [%{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "args",
            "type" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "LIST", "name" => nil, "ofType" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "OBJECT", "name" => "__InputValue"}}}}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "description", "type" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "name", "type" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "onField", "type" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "SCALAR", "name" => "Boolean", "ofType" => nil}}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "onFragment", "type" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "SCALAR", "name" => "Boolean", "ofType" => nil}}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "onOperation", "type" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "SCALAR", "name" => "Boolean", "ofType" => nil}}}], "inputFields" => nil, "interfaces" => [],
         "kind" => "OBJECT", "name" => "__Directive", "possibleTypes" => nil},
       %{"description" => "One possible value for a given Enum. Enum values are unique values, not\na placeholder for a string or numeric value. However an Enum value is\nreturned in a JSON response as a string.\n", "enumValues" => nil,
         "fields" => [%{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "deprecationReason", "type" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "description", "type" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "isDeprecated", "type" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "SCALAR", "name" => "Boolean", "ofType" => nil}}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "name", "type" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}}}], "inputFields" => nil, "interfaces" => [], "kind" => "OBJECT",
         "name" => "__EnumValue", "possibleTypes" => nil},
       %{"description" => "Object and Interface types are described by a list of Fields, each of\nwhich has a name, potentially a list of arguments, and a return type.\n", "enumValues" => nil,
         "fields" => [%{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "args",
            "type" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "LIST", "name" => nil, "ofType" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "OBJECT", "name" => "__InputValue"}}}}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "deprecationReason", "type" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "description", "type" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "isDeprecated", "type" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "SCALAR", "name" => "Boolean", "ofType" => nil}}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "name", "type" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "type", "type" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "OBJECT", "name" => "__Type", "ofType" => nil}}}], "inputFields" => nil, "interfaces" => [], "kind" => "OBJECT",
         "name" => "__Field", "possibleTypes" => nil},
       %{"description" => "Arguments provided to Fields or Directives and the input fields of an\nInputObject are represented as Input Values which describe their type\nand optionally a default value.\n", "enumValues" => nil,
         "fields" => [%{"args" => [], "deprecationReason" => nil, "description" => "A GraphQL-formatted string representing the default value for this input value.", "isDeprecated" => nil, "name" => "defaultValue", "type" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "description", "type" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "name", "type" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "type", "type" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "OBJECT", "name" => "__Type", "ofType" => nil}}}], "inputFields" => nil, "interfaces" => [], "kind" => "OBJECT",
         "name" => "__InputValue", "possibleTypes" => nil},
       %{"description" => "A GraphQL Schema defines the capabilities of a GraphQL server. It\nexposes all available types and directives on the server, as well as\nthe entry points for query, mutation, and subscription operations.\n", "enumValues" => nil,
         "fields" => [%{"args" => [], "deprecationReason" => nil, "description" => "A list of all directives supported by this server.", "isDeprecated" => nil, "name" => "directives",
            "type" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "LIST", "name" => nil, "ofType" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "OBJECT", "name" => "__Directive"}}}}},
          %{"args" => [], "deprecationReason" => nil, "description" => "If this server supports mutation, the type that mutation operations will be rooted at.", "isDeprecated" => nil, "name" => "mutationType", "type" => %{"kind" => "OBJECT", "name" => "__Type", "ofType" => nil}},
          %{"args" => [], "deprecationReason" => nil, "description" => "The type that query operations will be rooted at.", "isDeprecated" => nil, "name" => "queryType", "type" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "OBJECT", "name" => "__Type", "ofType" => nil}}},
          %{"args" => [], "deprecationReason" => nil, "description" => "If this server support subscription, the type that subscription operations will be rooted at.", "isDeprecated" => nil, "name" => "subscriptionType", "type" => %{"kind" => "OBJECT", "name" => "__Type", "ofType" => nil}},
          %{"args" => [], "deprecationReason" => nil, "description" => "A list of all types supported by this server.", "isDeprecated" => nil, "name" => "types",
            "type" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "LIST", "name" => nil, "ofType" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "OBJECT", "name" => "__Type"}}}}}], "inputFields" => nil, "interfaces" => [], "kind" => "OBJECT", "name" => "__Schema",
         "possibleTypes" => nil},
       %{"description" => "The fundamental unit of any GraphQL Schema is the type. There are\nmany kinds of types in GraphQL as represented by the `__TypeKind` enum.\n\nDepending on the kind of a type, certain fields describe\ninformation about that type. Scalar types provide no information\nbeyond a name and description, while Enum types provide their values.\nObject and Interface types provide the fields they describe. Abstract\ntypes, Union and Interface, provide the Object types possible\nat runtime. List and NonNull types compose other types.\n",
         "enumValues" => nil,
         "fields" => [%{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "description", "type" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}},
          %{"args" => [%{"defaultValue" => "false", "description" => nil, "name" => "includeDeprecated", "type" => %{"kind" => "SCALAR", "name" => "Boolean", "ofType" => nil}}], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "enumValues",
            "type" => %{"kind" => "LIST", "name" => nil, "ofType" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "OBJECT", "name" => "__EnumValue", "ofType" => nil}}}},
          %{"args" => [%{"defaultValue" => "false", "description" => nil, "name" => "includeDeprecated", "type" => %{"kind" => "SCALAR", "name" => "Boolean", "ofType" => nil}}], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "fields",
            "type" => %{"kind" => "LIST", "name" => nil, "ofType" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "OBJECT", "name" => "__Field", "ofType" => nil}}}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "inputFields", "type" => %{"kind" => "LIST", "name" => nil, "ofType" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "OBJECT", "name" => "__InputValue", "ofType" => nil}}}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "interfaces", "type" => %{"kind" => "LIST", "name" => nil, "ofType" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "OBJECT", "name" => "__Type", "ofType" => nil}}}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "kind", "type" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "ENUM", "name" => "__TypeKind", "ofType" => nil}}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "name", "type" => %{"kind" => "SCALAR", "name" => "String", "ofType" => nil}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "ofType", "type" => %{"kind" => "OBJECT", "name" => "__Type", "ofType" => nil}},
          %{"args" => [], "deprecationReason" => nil, "description" => nil, "isDeprecated" => nil, "name" => "possibleTypes", "type" => %{"kind" => "LIST", "name" => nil, "ofType" => %{"kind" => "NON_NULL", "name" => nil, "ofType" => %{"kind" => "OBJECT", "name" => "__Type", "ofType" => nil}}}}],
         "inputFields" => nil, "interfaces" => [], "kind" => "OBJECT", "name" => "__Type", "possibleTypes" => nil},
       %{"description" => "An enum describing what kind of type a given `__Type` is.",
         "enumValues" => [%{"deprecationReason" => nil, "description" => "Indicates this type is an enum. `enumValues` is a valid field.", "isDeprecated" => nil, "name" => "ENUM"},
          %{"deprecationReason" => nil, "description" => "Indicates this type is an input object. `inputFields` is a valid field.", "isDeprecated" => nil, "name" => "INPUT_OBJECT"},
          %{"deprecationReason" => nil, "description" => "Indicates this type is an interface. `fields` and `possibleTypes` are valid fields.", "isDeprecated" => nil, "name" => "INTERFACE"},
          %{"deprecationReason" => nil, "description" => "Indicates this type is a list. `ofType` is a valid field.", "isDeprecated" => nil, "name" => "LIST"},
          %{"deprecationReason" => nil, "description" => "Indicates this type is a non-null. `ofType` is a valid field.", "isDeprecated" => nil, "name" => "NON_NULL"},
          %{"deprecationReason" => nil, "description" => "Indicates this type is an object. `fields` and `interfaces` are valid fields.", "isDeprecated" => nil, "name" => "OBJECT"},
          %{"deprecationReason" => nil, "description" => "Indicates this type is a scalar.", "isDeprecated" => nil, "name" => "SCALAR"}, %{"deprecationReason" => nil, "description" => "Indicates this type is a union. `possibleTypes` is a valid field.", "isDeprecated" => nil, "name" => "UNION"}],
         "fields" => nil, "inputFields" => nil, "interfaces" => nil, "kind" => "ENUM", "name" => "__TypeKind", "possibleTypes" => nil}]}
      }
  end
end
