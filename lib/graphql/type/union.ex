defmodule GraphQL.Type.Union do
  defstruct name: "", description: "", resolver: nil, types: []

  def new(map) do
    struct(GraphQL.Type.Union, map)
  end

  defimpl GraphQL.AbstractTypes do
    def possible_type?(union, object, _) do
      Enum.any?(union.types, fn(t) -> t.name === object.name end)
    end

    def get_object_type(union, object, _) do
      union.resolver.(object)
    end
  end
end
