defmodule GraphQL.Schema do
  defstruct query: nil, mutation: nil

  def reduce_types(type), do: reduce_types(type, %{})
  def reduce_types(%GraphQL.Type.List{of_type: list_type}, typemap), do: reduce_types(list_type, typemap)

  def reduce_types(%GraphQL.Type.Interface{} = type, typemap) do
    IO.puts "Working on an interface... ... #{type.name}"
    typemap
  end

  def reduce_types(type, typemap) do
    IO.inspect "Starting reduction of #{type.name}"
    IO.inspect "Right now typemap is #{inspect typemap}"
    typemap = Map.put(typemap, type.name, %{name: type.name}) # replace with `type`, and convert to Field?

    IO.inspect Map.keys(type)
    typemap = case type do
      %GraphQL.Type.ObjectType{} ->
        IO.inspect "reducing over object type's fields"
        IO.inspect type
        Enum.reduce(type.fields, typemap, fn({name,fieldtype},map) ->
          IO.inspect name
          IO.inspect fieldtype.type
          # do the args, too...
          reduce_types(fieldtype.type, map)
        end)
        %GraphQL.Type.Enum{} -> typemap # explicitely do nothing, so that we know we've handled this type in development
        %GraphQL.Type.ID{} -> typemap
        %GraphQL.Type.String{} -> typemap
    end
  end
end
