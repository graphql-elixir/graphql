defmodule GraphQL.Type.ID do
  defstruct name: "ID", description:
    """
    The `ID` scalar type represents a unique identifier, often used to
    refetch an object or as key for a cache. The ID type appears in a JSON
    response as a String; however, it is not intended to be human-readable.
    When expected as an input type, any string (such as `"4"`) or integer
    (such as `4`) input value will be accepted as an ID.
    """

  def coerce(value), do: to_string(value)
end

defimpl GraphQL.Types, for: GraphQL.Type.ID do
  def parse_value(_, value), do: GraphQL.Type.String.coerce(value)
  def serialize(_, value), do: GraphQL.Type.String.coerce(value)
end
