defmodule GraphQL.Type.Interface do
  defstruct name: "", description: "", fields: %{}, resolver: nil

  def new(map) do
    struct(GraphQL.Type.Interface, map)
  end

  @doc """
  Unlike Union, Interfaces don't explicitly declare what Types implement them,
  so we have to iterate over a full typemap and filter the Types in the Schema
  down to just those that implement the provided interface.
  """
  @spec possible_types(%GraphQL.Type.Interface{}, %GraphQL.Schema{}) :: [%GraphQL.Type.ObjectType{}]
  def possible_types(interface, schema) do
    # get the complete typemap from this scheme
    GraphQL.Schema.reduce_types(schema)
    # filter them down to a list of types that implement this interface
    |> Enum.filter(fn {_, typedef} -> GraphQL.Type.implements?(typedef, interface) end)
    # then return the type, instead of the {name, type} tuple that comes from
    # the reduce_types call
    |> Enum.map(fn({_,v}) -> v end)
  end

  defimpl GraphQL.AbstractTypes do
    @doc """
    Returns a boolean indicating if the provided type implements the interface
    """
    def possible_type?(interface, object) do
      GraphQL.Type.implements?(object, interface)
    end

    @doc """
    Returns the typedef of the provided Object using either the Interface's
    resolve function (if it exists), or by iterating over all the typedefs that
    implement this Interface and returning the first one that matches against
    the Object's isTypeOf function.
    """
    def get_object_type(interface, object, schema) do
      if interface.resolver do
        interface.resolver.(object)
      else
        GraphQL.Type.Interface.possible_types(interface, schema)
        |> Enum.find(fn(x) -> x.isTypeOf.(object) end)
      end
    end
  end
end
