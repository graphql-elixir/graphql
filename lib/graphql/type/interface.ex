defmodule GraphQL.Type.Interface do
  defstruct name: "", description: "", fields: %{}, resolver: nil

  def new(map) do
    struct(GraphQL.Type.Interface, map)
  end

  @doc """
    Takes flat list of types from the provided schema, and returns a list
    of the types that impliment the provided interface
  """
  def possible_types(interface, schema) do
    # get the flattened list of types
    GraphQL.Schema.reduce_types(schema)
    # filter down to a list of types
    |> Enum.filter(fn {_, t} ->
        # by getting their interfaces, or an empty list
        Map.get(t, :interfaces, [])
        # and checking if any of them match the provided interface name
        |> Enum.map(&(&1.name))
        |> Enum.member?(interface.name)
    end)
    # then return the type, instead of the {name, type} tuple
    |> Enum.map(fn({_,v}) -> v end)
  end

  defimpl GraphQL.AbstractTypes do
    def possible_type?(interface, object, info) do
      GraphQL.Type.Interface.possible_types(interface, info.schema)
      |> Enum.map(&(&1.name))
      |> Enum.member?(object.name)
    end

    def get_object_type(interface, object, info) do
      if interface.resolver do
        interface.resolver.(object)
      else
        GraphQL.Type.Interface.possible_types(interface, info.schema)
        |> Enum.filter(fn(x) -> x.isTypeOf.(object) end)
        |> hd
      end
    end
  end
end
