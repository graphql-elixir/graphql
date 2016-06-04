defmodule GraphQL.Type.Introspection do

  alias GraphQL.Type.ObjectType
  alias GraphQL.Type.Interface
  alias GraphQL.Type.Input
  alias GraphQL.Type.Union
  alias GraphQL.Type.List
  alias GraphQL.Type.NonNull
  alias GraphQL.Type.String
  alias GraphQL.Type.Boolean
  alias GraphQL.Type.CompositeType
  alias GraphQL.Type.AbstractType

  alias GraphQL.Type.Introspection.Schema
  alias GraphQL.Type.Introspection.Directive
  alias GraphQL.Type.Introspection.Type
  alias GraphQL.Type.Introspection.TypeKind
  alias GraphQL.Type.Introspection.Field
  alias GraphQL.Type.Introspection.InputValue
  alias GraphQL.Type.Introspection.EnumValue

  alias GraphQL.Util.Text

  defmodule Schema do
    def type do
      %ObjectType{
        name: "__Schema",
        description:
          """
          A GraphQL Schema defines the capabilities of a GraphQL server. It
          exposes all available types and directives on the server, as well as
          the entry points for query, mutation, and subscription operations.
          """ |> Text.normalize,
        fields: %{
          types: %{
            description: "A list of all types supported by this server.",
            type: %NonNull{ofType: %List{ofType: %NonNull{ofType: Type}}},
            resolve: fn(schema) ->
              Map.values(schema.type_cache)
            end
          },
          queryType: %{
            description: "The type that query operations will be rooted at.",
            type: %NonNull{ofType: Type},
            resolve: fn(%{query: query}) -> query end
          },
          mutationType: %{
            description: "If this server supports mutation, the type that mutation operations will be rooted at.",
            type: Type,
            resolve: fn(%{mutation: mutation}) -> mutation end
          },
          subscriptionType: %{
            description: "If this server support subscription, the type that subscription operations will be rooted at.",
            type: Type,
            resolve: nil #fn(%{subscription: subscription}, _, _,_) -> subscription end
          },
          directives: %{
            description: "A list of all directives supported by this server.",
            type: %NonNull{ofType: %List{ofType: %NonNull{ofType: Directive}}},
            resolve: fn(schema, _, _) ->
              schema.directives
            end
          }
        }
      }
    end
  end

  defmodule Directive do
    def type do
      %ObjectType{
        name: "__Directive",
        description:
          """
          A Directive provides a way to describe alternate runtime execution and
          type validation behavior in a GraphQL document.

          In some cases, you need to provide options to alter GraphQL’s
          execution behavior in ways field arguments will not suffice, such as
          conditionally including or skipping a field. Directives provide this by
          describing additional information to the executor
          """ |> Text.normalize,
        fields: %{
          name: %{type: %NonNull{ofType: %String{}}},
          description: %{type: %String{}},
          args: %{
            type: %NonNull{ofType: %List{ofType: %NonNull{ofType: InputValue}}},
            resolve: fn
              %{args: args}, _, _ ->
                Enum.map(args, fn {name, v} -> Map.put(v, :name, name) end)
              _, _, _ ->  []
            end
          },
          onOperation: %{type: %NonNull{ofType: %Boolean{}}},
          onFragment: %{type: %NonNull{ofType: %Boolean{}}},
          onField: %{type: %NonNull{ofType: %Boolean{}}},
        }
      }
    end
  end

  defmodule Type do
    def type do
      %ObjectType{
        name: "__Type",
        description:
          """
          The fundamental unit of any GraphQL Schema is the type. There are
          many kinds of types in GraphQL as represented by the `__TypeKind` enum.

          Depending on the kind of a type, certain fields describe
          information about that type. Scalar types provide no information
          beyond a name and description, while Enum types provide their values.
          Object and Interface types provide the fields they describe. Abstract
          types, Union and Interface, provide the Object types possible
          at runtime. List and NonNull types compose other types.
          """ |> Text.normalize,
        fields: %{
          kind: %{
            type: %NonNull{ofType: TypeKind},
            resolve: fn(schema) ->
              case schema do
                %ObjectType{} -> "OBJECT"
                %Interface{} -> "INTERFACE"
                %Union{} -> "UNION"
                %GraphQL.Type.Enum{} -> "ENUM"
                %Input{} -> "INPUT_OBJECT"
                %List{} -> "LIST"
                %NonNull{} -> "NON_NULL"
                # since we can't subclass, maybe we can just check
                # if the thing is a map and assume it's a scalar by
                # default. otherwise we need checks for int/float/boolean
                # etc etc etc any any custom types. We also sort of need
                # some sort of injection for custom types :-\
                # maybe attaching it to the type's module?
                _ -> "SCALAR"
              end
            end
          },
          name: %{type: %String{}},
          description: %{type: %String{}},
          fields: %{
            type: %List{ofType: %NonNull{ofType: Field}},
            args: %{includeDeprecated: %{type: %Boolean{}, defaultValue: false}},
            resolve: fn
              (%ObjectType{} = schema) ->
                thunk_fields = CompositeType.get_fields(schema)
                Enum.map(thunk_fields, fn({n, v}) -> Map.put(v, :name, n) end)
                # |> filter_deprecated
              (%Interface{} = schema) ->
                thunk_fields = CompositeType.get_fields(schema)
                Enum.map(thunk_fields, fn({n, v}) -> Map.put(v, :name, n) end)
              (_) -> nil
            end
          },
          interfaces: %{
            type: %List{ofType: %NonNull{ofType: Type}},
            resolve: fn
              (%ObjectType{} = schema) ->
                schema.interfaces
              (_) -> nil
            end
          },
          possibleTypes: %{
            type: %List{ofType: %NonNull{ofType: Type}},
            resolve: fn
              (%GraphQL.Type.Interface{name: _name} = interface, _args, info) ->
                AbstractType.possible_types(interface, info.schema)
              (%GraphQL.Type.Union{name: name}, _args, info) ->
                info.schema.type_cache[name].types
              (_, _, _) -> nil
            end
          },
          enumValues: %{
            type: %List{ofType: %NonNull{ofType: EnumValue}},
            args: %{includeDeprecated: %{type: %Boolean{}, defaultValue: false}},
            resolve: fn
              (%GraphQL.Type.Enum{} = schema) -> schema.values
              (_) -> nil
            end
          },
          inputFields: %{
            type: %List{ofType: %NonNull{ofType: InputValue}},
            resolve: fn
              (%GraphQL.Type.Input{} = type) ->
                fields = type.fields
                Enum.map(Map.keys(fields), fn(key) ->
                  %{
                    name: key,
                    type: fields[key].type
                  }
                end)
              (_) -> nil
            end
          },
          ofType: %{type: Type}
        }
      }
    end
  end

  defmodule TypeKind do
    def type do
      %{
        name: "__TypeKind",
        description: "An enum describing what kind of type a given `__Type` is.",
        values: %{
          SCALAR: %{
            value: "SCALAR",
            description: "Indicates this type is a scalar."
          },
          OBJECT: %{
            value: "OBJECT",
            description: "Indicates this type is an object. `fields` and `interfaces` are valid fields."
          },
          INTERFACE: %{
            value: "INTERFACE",
            description: "Indicates this type is an interface. `fields` and `possibleTypes` are valid fields."
          },
          UNION: %{
            value: "UNION",
            description: "Indicates this type is a union. `possibleTypes` is a valid field."
          },
          ENUM: %{
            value: "ENUM",
            description: "Indicates this type is an enum. `enumValues` is a valid field."
          },
          INPUT_OBJECT: %{
            value: "INPUT_OBJECT",
            description: "Indicates this type is an input object. `inputFields` is a valid field."
          },
          LIST: %{
            value: "LIST",
            description: "Indicates this type is a list. `ofType` is a valid field."
          },
          NON_NULL: %{
            value: "NON_NULL",
            description: "Indicates this type is a non-null. `ofType` is a valid field."
          }
        }
      } |> GraphQL.Type.Enum.new
    end
  end

  defmodule Field do
    def type do
      %ObjectType{
        name: "__Field",
        description:
          """
          Object and Interface types are described by a list of Fields, each of
          which has a name, potentially a list of arguments, and a return type.
          """ |> Text.normalize,
        fields: %{
          name: %{type: %NonNull{ofType: %String{}}},
          description: %{type: %String{}},
          args: %{
            type: %NonNull{ofType: %List{ofType: %NonNull{ofType: InputValue}}},
            resolve: fn
              %{args: args} ->
                Enum.map(args, fn {name, v} -> Map.put(v, :name, name) end)
              _ -> []
            end
          },
          type: %{type: %NonNull{ofType: Type}},
          isDeprecated: %{
            type: %NonNull{ofType: %Boolean{}}
            # resolve: field => !isNullish(field.deprecationReason),
          },
          deprecationReason: %{type: %String{}}
        }
      }
    end
  end

  defmodule InputValue do
    def type do
      %ObjectType{
        name: "__InputValue",
        description:
          """
          Arguments provided to Fields or Directives and the input fields of an
          InputObject are represented as Input Values which describe their type
          and optionally a default value.
          """ |> Text.normalize,
        fields: %{
          name: %{type: %NonNull{ofType: %String{}}},
          description: %{type: %String{}},
          type: %{type: %NonNull{ofType: Type}},
          defaultValue: %{
            type: %String{},
            description: "A GraphQL-formatted string representing the default value for this input value."
            # resolve: inputVal => isNullish(inputVal.defaultValue) ?
            #   null :
            #   print(astFromValue(inputVal.defaultValue, inputVal))
          }
        }
      }
    end
  end

  defmodule EnumValue do
    def type do
      %ObjectType{
        name: "__EnumValue",
        description:
          """
          One possible value for a given Enum. Enum values are unique values, not
          a placeholder for a string or numeric value. However an Enum value is
          returned in a JSON response as a string.
          """ |> Text.normalize,
        fields: %{
          name: %{type: %NonNull{ofType: %String{}}},
          description: %{type: %String{}},
          isDeprecated: %{
            type: %NonNull{ofType: %Boolean{}}
            # resolve: enumValue => !isNullish(enumValue.deprecationReason),
          },
          deprecationReason: %{type: %String{}}
        }
      }
    end
  end

  def query do
    """
    query IntrospectionQuery {
      __schema {
        queryType { name }
        mutationType { name }
        subscriptionType { name }
        types {
          ...FullType
        }
        directives {
          name
          description
          args {
            ...InputValue
          }
          onOperation
          onFragment
          onField
        }
      }
    }

    fragment FullType on __Type {
      kind
      name
      description
      fields(includeDeprecated: true) {
        name
        description
        args {
          ...InputValue
        }
        type {
          ...TypeRef
        }
        isDeprecated
        deprecationReason
      }
      inputFields {
        ...InputValue
      }
      interfaces {
        ...TypeRef
      }
      enumValues(includeDeprecated: true) {
        name
        description
        isDeprecated
        deprecationReason
      }
      possibleTypes {
        ...TypeRef
      }
    }

    fragment InputValue on __InputValue {
      name
      description
      type { ...TypeRef }
      defaultValue
    }

    fragment TypeRef on __Type {
      kind
      name
      ofType {
        kind
        name
        ofType {
          kind
          name
          ofType {
            kind
            name
          }
        }
      }
    }
    """
  end

  def meta(:type) do
    %{
      name: "__type",
      type: Type,
      description: "Request the type information of a single type.",
      args: %{
        name: %{type: %NonNull{ofType: %String{}}}
      },
      resolve: fn(_, %{name: name}, %{schema: schema}) ->
        schema.type_cache[name]
      end
    }
  end

  def meta(:typename) do
    %{
      name: "__typename",
      type: %NonNull{ofType: %String{}},
      description: "The name of the current Object type at runtime.",
      resolve: fn
        (_, _, %{parent_type: %{name: name}}) -> name
        (_, _, %{parent_type: module}) -> apply(module, :type, [])
      end
    }
  end

  def meta(:schema) do
    %{
      name: "__schema",
      type: %NonNull{ofType: Schema},
      description: "Access the current type schema of this server.",
      resolve: fn(_, _, args) -> args.schema end
    }
  end
end
