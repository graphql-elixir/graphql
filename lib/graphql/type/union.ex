defmodule GraphQL.Type.Union do
  @type t :: %GraphQL.Type.Union{
    name: binary,
    description: binary | nil,
    resolver: (any -> GraphQL.Type.ObjectType.t),
    types: [GraphQL.Type.ObjectType.t]
  }
  defstruct name: "", description: "", resolver: nil, types: []

  def new(map) do
    struct(GraphQL.Type.Union, map)
  end

  defimpl GraphQL.AbstractType do
    @doc """
    Returns a boolean indicating if the typedef provided is part of the provided
    union type.
    """
    def possible_type?(union, object) do
      Enum.any?(union.types, fn(t) -> t.name === object.name end)
    end

    @doc """
    Returns the typedef for the object that was passed in, which could be a
    struct or map.
    """
    def get_object_type(union, object, _) do
      union.resolver.(object)
    end
  end
end
