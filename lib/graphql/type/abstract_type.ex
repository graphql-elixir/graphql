defprotocol GraphQL.Type.AbstractType do
  @type t :: GraphQL.Type.Union.t | GraphQL.Type.Interface.t

  @spec possible_type?(GraphQL.AbstractType.t, GraphQL.Type.Object.t) :: boolean
  def possible_type?(abstract_type, object)

  @spec possible_types(GraphQL.AbstractType.t, GraphQL.Schema.t) :: [GraphQL.Type.Object.t]
  def possible_types(abstract_type, schema)

  @spec get_object_type(GraphQL.AbstractType.t, %{}, GraphQL.Schema.t) :: GraphQL.Type.Object.t
  def get_object_type(abstract_type, object, schema)
end
