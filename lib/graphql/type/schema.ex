defmodule GraphQL.Schema do
  @type t :: %GraphQL.Schema{
    query: Map,
    mutation: Map,
    types: [GraphQL.AbstractType.t | GraphQL.Type.ObjectType.t]
  }
  defstruct query: nil, mutation: nil, types: []

  def type_from_ast(nil, _), do: nil
  def type_from_ast(%{kind: :NamedType} = input_type_ast, schema) do
    reduce_types(schema) |> Map.get(input_type_ast.name.value, :not_found)
  end

  def reduce_types(type) do
    %{}
    |> reduce_types(type.query)
    |> reduce_types(type.mutation)
    |> reduce_types(GraphQL.Type.Introspection.schema)
  end

  def reduce_types(typemap, %GraphQL.Type.List{ofType: list_type}), do: reduce_types(typemap, list_type)
  def reduce_types(typemap, %GraphQL.Type.NonNull{ofType: list_type}), do: reduce_types(typemap, list_type)

  def reduce_types(typemap, %GraphQL.Type.Interface{} = type) do
    Map.put(typemap, type.name, type)
  end

  def reduce_types(typemap, %GraphQL.Type.Union{} = type) do
    typemap = Map.put(typemap, type.name, type)
    Enum.reduce(type.types, typemap, fn(fieldtype,map) ->
       reduce_types(map, fieldtype)
    end)
  end

  def reduce_types(typemap, %GraphQL.Type.ObjectType{} = type) do
    if Map.has_key?(typemap, type.name) do
      typemap
    else
      typemap = Map.put(typemap, type.name, type)
      thunk_fields = GraphQL.Execution.Executor.maybe_unwrap(type.fields)
      typemap = Enum.reduce(thunk_fields, typemap, fn({_,fieldtype},map) ->
        reduce_types(map, fieldtype.type)
      end)
      Enum.reduce(type.interfaces, typemap, fn(fieldtype,map) ->
       reduce_types(map, fieldtype)
      end)
    end
  end
  def reduce_types(typemap, %{name: name} = type), do: Map.put(typemap, name, type)
  def reduce_types(typemap, nil), do: typemap
end
