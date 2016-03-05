defprotocol GraphQL.AbstractType do
  @type t :: GraphQL.Type.Union.t | GraphQL.Type.Interface.t

  @spec possible_type?(GraphQL.AbstractType.t, GraphQL.Type.ObjectType.t) :: boolean
  def possible_type?(abstract_type, object)

  @spec get_object_type(GraphQL.AbstractType.t, %{}, GraphQL.Schema.t) :: GraphQL.Type.ObjectType.t
  def get_object_type(abstract_type, object, schema)
end
