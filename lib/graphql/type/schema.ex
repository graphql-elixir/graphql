defmodule GraphQL.Schema do

  @type t :: %GraphQL.Schema{
    query: Map,
    mutation: Map,
    types: [GraphQL.Type.AbstractType.t | GraphQL.Type.ObjectType.t]
  }

  alias GraphQL.Type.Interface
  alias GraphQL.Type.Union
  alias GraphQL.Type.ObjectType
  alias GraphQL.Type.Introspection
  alias GraphQL.Type.CompositeType

  defstruct query: nil, mutation: nil, types: []

  # FIXME: I think *schema* should be the first argument in this module.
  def type_from_ast(nil, _), do: nil
  def type_from_ast(%{kind: :NonNullType,} = input_type_ast, schema) do
    %GraphQL.Type.NonNull{ofType: type_from_ast(input_type_ast.type, schema)}
  end
  def type_from_ast(%{kind: :ListType,} = input_type_ast, schema) do
    %GraphQL.Type.List{ofType: type_from_ast(input_type_ast.type, schema)}
  end
  def type_from_ast(%{kind: :NamedType} = input_type_ast, schema) do
    reduce_types(schema) |> Map.get(input_type_ast.name.value, :not_found)
  end

  def reduce_types(type) do
    %{}
    |> reduce_types(type.query)
    |> reduce_types(type.mutation)
    |> reduce_types(Introspection.Schema.type)
  end

  def reduce_types(typemap, %{ofType: list_type}) do
    reduce_types(typemap, list_type)
  end

  def reduce_types(typemap, %Interface{} = type) do
    Map.put(typemap, type.name, type)
  end

  def reduce_types(typemap, %Union{} = type) do
    typemap = Map.put(typemap, type.name, type)
    Enum.reduce(type.types, typemap, fn(fieldtype,map) ->
       reduce_types(map, fieldtype)
    end)
  end

  def reduce_types(typemap, %ObjectType{} = type) do
    if Map.has_key?(typemap, type.name) do
      typemap
    else
      typemap = Map.put(typemap, type.name, type)
      thunk_fields = CompositeType.get_fields(type)
      typemap = Enum.reduce(thunk_fields, typemap, fn({_,fieldtype},typemap) ->
        _reduce_arguments(typemap, fieldtype)
        |> reduce_types(fieldtype.type)
      end)
      typemap = Enum.reduce(type.interfaces, typemap, fn(fieldtype,map) ->
       reduce_types(map, fieldtype)
      end)
    end
  end

  def reduce_types(typemap, %{name: name} = type), do: Map.put(typemap, name, type)
  def reduce_types(typemap, nil), do: typemap

  def reduce_types(typemap, type_module) when is_atom(type_module) do
    reduce_types(typemap, apply(type_module, :type, []))
  end

  defp _reduce_arguments(typemap, %{args: args}) do
    field_arg_types = Enum.map(args, fn{_,v} -> v.type end)
    Enum.reduce(field_arg_types, typemap, fn(fieldtype,typemap) ->
      reduce_types(typemap, fieldtype)
    end)
  end
  defp _reduce_arguments(typemap, _), do: typemap
end
