defmodule GraphQL.Type.Interface do
  defstruct name: "", description: "", fields: %{}, resolver: nil

  def new(map) do
    struct(GraphQL.Type.Interface, map)
  end

  def get_object_type(interface, object) do
    interface.resolver.(object)
  end
end
