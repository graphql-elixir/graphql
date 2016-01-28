defmodule GraphQL.Type.Introspection do

  alias GraphQL.Type.ObjectType
  alias GraphQL.Type.List
  alias GraphQL.Type.NonNull
  alias GraphQL.Type.String
  alias GraphQL.Type.Boolean

  def schema do
    %ObjectType{
      name: "__Schema",
      description:
        """
        A GraphQL Schema defines the capabilities of a GraphQL server. It
        exposes all available types and directives on the server, as well as
        the entry points for query, mutation, and subscription operations.
        """,
      fields: quote do %{
        types: %{
          description: "A list of all types supported by this server.",
          type: %NonNull{ofType: %List{ofType: %NonNull{ofType: GraphQL.Type.Introspection.type}}},
          resolve: fn(schema, _, _) ->
            Map.values(GraphQL.Schema.reduce_types(schema))
          end
        },
        queryType: %{
          description: "The type that query operations will be rooted at.",
          type: %NonNull{ofType: GraphQL.Type.Introspection.type},
          resolve: fn(%{query: query}, _, _) -> query end
        },
        mutationType: %{
          description: "If this server supports mutation, the type that mutation operations will be rooted at.",
          type: GraphQL.Type.Introspection.type,
          resolve: nil #fn(%{mutation: mutation}, _, _) -> mutation end
        },
        subscriptionType: %{
          description: "If this server support subscription, the type that subscription operations will be rooted at.",
          type: GraphQL.Type.Introspection.type,
          resolve: nil #fn(%{subscription: subscription}, _, _) -> subscription end
        },
        directives: %{
          description: "A list of all directives supported by this server.",
          type: %NonNull{ofType: %List{ofType: %NonNull{ofType: GraphQL.Type.Introspection.directive}}},
          resolve: nil #schema => schema.getDirectives(),
        }
      } end
    }
  end

  def directive do
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
        """,
      fields: %{
        name: %{type: %NonNull{ofType: %String{}}},
        description: %{type: %String{}},
        args: %{
          type: %NonNull{ofType: %List{ofType: %NonNull{ofType: input_value}}},
          resolve: nil #directive => directive.args || []
        },
        onOperation: %{type: %NonNull{ofType: %Boolean{}}},
        onFragment: %{type: %NonNull{ofType: %Boolean{}}},
        onField: %{type: %NonNull{ofType: %Boolean{}}},
      }
    }
  end

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
        """,
      fields: quote do %{
        kind: %{
          type: %NonNull{ofType: GraphQL.Type.Introspection.typekind},
          resolve: fn(schema, _, _) ->
            case schema do
              %GraphQL.Type.ScalarType{} -> "SCALAR"
              %GraphQL.Type.ObjectType{} -> "OBJECT"
              %GraphQL.Type.Interface{} -> "INTERFACE"
              #%GraphQL.Type.Union{} -> "UNION"
              %GraphQL.Type.Enum{} -> "ENUM"
              #%GraphQL.Type.Input{} -> "INPUT_OBJECT"
              %GraphQL.Type.List{} -> "LIST"
              %GraphQL.Type.NonNull{} -> "NON_NULL"
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
          type: %List{ofType: %NonNull{ofType: GraphQL.Type.Introspection.field}},
          args: %{includeDeprecated: %{type: %Boolean{}, defaultValue: false}},
          resolve: fn
            (%GraphQL.Type.ObjectType{} = schema, args, rest) ->
              thunk_fields = GraphQL.Execution.Executor.maybe_unwrap(schema.fields)
              Enum.map(thunk_fields, fn({n, v}) -> Map.put(v, :name, n) end)
              # |> filter_deprecated
            (%GraphQL.Type.Interface{} = schema, args, rest) ->
              thunk_fields = GraphQL.Execution.Executor.maybe_unwrap(schema.fields)
              Enum.map(thunk_fields, fn({n, v}) -> Map.put(v, :name, n) end)
            (s, _, _) ->
              []
          end
          # resolve(type, { includeDeprecated }) {
          #   if (type instanceof GraphQLObjectType ||
          #       type instanceof GraphQLInterfaceType) {
          #     var fieldMap = type.getFields();
          #     var fields =
          #       Object.keys(fieldMap).map(fieldName => fieldMap[fieldName]);
          #     if (!includeDeprecated) {
          #       fields = fields.filter(field => !field.deprecationReason);
          #     }
          #     return fields;
          #   }
          #   return null;
          # }
        },
        interfaces: %{
          type: %List{ofType: %NonNull{ofType: GraphQL.Type.Introspection.type}},
          resolve: fn
            (%GraphQL.Type.ObjectType{} = schema, args, rest) ->
              schema.interfaces
            (_, _, _) -> nil
          end
        },
        possibleTypes: %{
          type: %List{ofType: %NonNull{ofType: GraphQL.Type.Introspection.type}},
          resolve: fn
            (%GraphQL.Type.Interface{name: name}, args, info) ->
              # TODO simplify this logic
              GraphQL.Schema.reduce_types(info.schema)
              |> Enum.filter(fn {_, t} ->
                Map.get(t, :interfaces, [])
                |> Enum.filter(&(&1.name === name)) !== []
              end) |> Enum.map(fn({k,v}) -> v end)
            (_, _, _) -> nil
          end
          # resolve(type) {
          #   if (type instanceof GraphQLInterfaceType ||
          #       type instanceof GraphQLUnionType) {
          #     return type.getPossibleTypes();
          #   }
          # }
        },
        enumValues: %{
          type: %List{ofType: %NonNull{ofType: GraphQL.Type.Introspection.enum_value}},
          args: %{includeDeprecated: %{type: %Boolean{}, defaultValue: false}},
          resolve: fn
            (%GraphQL.Type.Enum{} = schema, _, _) -> schema.values
            (_,_,_) -> nil
          end
          # resolve(type, { includeDeprecated }) {
          #   if (type instanceof GraphQLEnumType) {
          #     var values = type.getValues();
          #     if (!includeDeprecated) {
          #       values = values.filter(value => !value.deprecationReason);
          #     }
          #     return values;
          #   }
          # }
        },
        inputFields: %{
          type: %List{ofType: %NonNull{ofType: GraphQL.Type.Introspection.input_value}},
          resolve: nil
          # resolve(type) {
          #   if (type instanceof GraphQLInputObjectType) {
          #     var fieldMap = type.getFields();
          #     return Object.keys(fieldMap).map(fieldName => fieldMap[fieldName]);
          #   }
          # }
        },
        ofType: %{type: GraphQL.Type.Introspection.type}
      } end
    }
  end

  def typekind do
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

  def field do
    %ObjectType{
      name: "__Field",
      description:
        """
        Object and Interface types are described by a list of Fields, each of
        which has a name, potentially a list of arguments, and a return type.
        """,
      fields: %{
        name: %{type: %NonNull{ofType: %String{}}},
        description: %{type: %String{}},
        args: %{
          type: %NonNull{ofType: %List{ofType: %NonNull{ofType: GraphQL.Type.Introspection.input_value}}},
          resolve: fn
            (%{args: _args} = schema, _, _) -> Enum.map(schema.args, fn({name,v}) -> Map.put(v, :name, name) end)
            (_, _, _) ->  []
          end
        },
        type: %{type: %NonNull{ofType: GraphQL.Type.Introspection.type}},
        isDeprecated: %{
          type: %NonNull{ofType: %Boolean{}}
          # resolve: field => !isNullish(field.deprecationReason),
        },
        deprecationReason: %{type: %String{}}
      }
    }
  end

  def input_value do
    %ObjectType{
      name: "__InputValue",
      description:
        """
        Arguments provided to Fields or Directives and the input fields of an
        InputObject are represented as Input Values which describe their type
        and optionally a default value.
        """,
      fields: %{
        name: %{type: %NonNull{ofType: %String{}}},
        description: %{type: %String{}},
        type: %{type: %NonNull{ofType: GraphQL.Type.Introspection.type}},
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

  def enum_value do
    %ObjectType{
      name: "__EnumValue",
      description:
        """
        One possible value for a given Enum. Enum values are unique values, not
        a placeholder for a string or numeric value. However an Enum value is
        returned in a JSON response as a string.
        """,
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

  def meta("type") do
    %{
      name: "__type",
      type: GraphQL.Type.Introspection.type,
      description: "Request the type information of a single type.",
      args:
        %{
          name: %{type: %NonNull{ofType: %String{}}}
        },
      resolve: fn(_, %{name: name}, %{schema: schema}) ->
        GraphQL.Schema.reduce_types(schema)[name]
      end
    }
  end

  def meta("typename") do
    %{
      name: "__typename",
      type: %NonNull{ofType: %String{}},
      description: "The name of the current Object type at runtime.",
      args: [],
      resolve: fn(_, _, %{parent_type: %{name: name}}) -> name end
    }
  end

  def meta("schema") do
    %{
      name: "__schema",
      type: %NonNull{ofType: GraphQL.Type.Introspection.schema},
      description: "Access the current type schema of this server.",
      args: [],
      resolve: fn(_, _, args) -> args.schema end
    }
  end

end
