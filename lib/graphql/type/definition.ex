# TODO think of a better name for this protocol:
# Typed, TypeProtocol
defprotocol GraphQL.Types do
  @fallback_to_any true
  def parse_value(_, _)
  def serialize(_, _)
end

defimpl GraphQL.Types, for: Any do
  def parse_value(_, v), do:  v
  def serialize(_, v), do: v
end

defmodule GraphQL.Type do

  defmodule ObjectType do
    defstruct name: "", description: "", fields: %{}, interfaces: []
  end

  defmodule ScalarType do
    defstruct name: "", description: ""
  end

  defmodule List do
    defstruct ofType: nil
  end

  defmodule NonNull do
    defstruct ofType: nil
  end
end
