defmodule GraphQL.Type.String do
  defstruct name: "String", description:
    """
    The `String` scalar type represents textual data, represented as UTF-8
    character sequences. The String type is most often used by GraphQL to
    represent free-form human-readable text.
    """

  def coerce(value), do: to_string(value)
end

defimpl GraphQL.Types, for: GraphQL.Type.String do
  def parse_value(_, value), do: GraphQL.Type.String.coerce(value)
  def serialize(_, value), do: GraphQL.Type.String.coerce(value)
end
