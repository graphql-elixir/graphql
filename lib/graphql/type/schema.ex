defmodule GraphQL.Schema do
  defstruct query: nil, mutation: nil, types: []

  def reduce_types(type) do
    o = reduce_types(type.query, %{})
    reduce_types(GraphQL.Type.Introspection.schema, o)
  end

  def reduce_types(%GraphQL.Type.List{of_type: list_type}, typemap), do: reduce_types(list_type, typemap)
  def reduce_types(%GraphQL.Type.NonNull{of_type: list_type}, typemap), do: reduce_types(list_type, typemap)

  def reduce_types(%GraphQL.Type.Interface{} = type, typemap) do
    Map.put(typemap, type.name, type)
  end

  def reduce_types(%GraphQL.Type.Enum{} = type, typemap) do
    Map.put(typemap, type.name, type)
  end
  def reduce_types(%GraphQL.Type.Boolean{} = type, typemap), do: Map.put(typemap, type.name, type)
  def reduce_types(%GraphQL.Type.ID{} = type, typemap), do: Map.put(typemap, type.name, type)
  def reduce_types(%GraphQL.Type.String{} = type, typemap), do: Map.put(typemap, type.name, type)

  def reduce_types(type, typemap) do
    if Map.has_key?(typemap, type.name) do
      typemap
    else
      typemap = Map.put(typemap, type.name, type)
      case type do
        %GraphQL.Type.ObjectType{} ->
          thunk_fields = GraphQL.Execution.Executor.maybe_unwrap(type.fields)
          Enum.reduce(thunk_fields, typemap, fn({_,fieldtype},map) ->
            reduce_types(fieldtype.type, map)
          end)
      end
    end
  end
end
