# TODO think of a better name for this protocol:
# Typed, TypeProtocol
defprotocol GraphQL.Types do
  @fallback_to_any true
  def parse_value(_, _)
  def serialize(_, _)
end

defprotocol GraphQL.AbstractTypes do
  def possible_type?(_, _, _)
  def get_object_type(_, _, _)
end

defimpl GraphQL.Types, for: Any do
  def parse_value(_, v), do:  v
  def serialize(_, v), do: v
end

defmodule GraphQL.Type do
  defmodule ObjectType do
    defstruct name: "", description: "", fields: %{}, interfaces: [], isTypeOf: nil
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

  def is_abstract?(%GraphQL.Type.Union{}), do: true
  def is_abstract?(%GraphQL.Type.Interface{}), do: true
  def is_abstract?(_), do: false

  def is_named?(%GraphQL.Type.ObjectType{}), do: true
  def is_named?(_), do: false
end
