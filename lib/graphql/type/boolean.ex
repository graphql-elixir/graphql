defmodule GraphQL.Type.Boolean do
  defstruct name: "Boolean", description:
    """
    The `Boolean` scalar type represents `true` or `false`.
    """

  def coerce(""), do: false
  def coerce(0), do: false
  def coerce(value), do: !!value
end

defimpl GraphQL.Types, for: GraphQL.Type.Boolean do
  def parse_value(_, value), do: GraphQL.Type.Boolean.coerce(value)
  def serialize(_, value), do: GraphQL.Type.Boolean.coerce(value)
end
