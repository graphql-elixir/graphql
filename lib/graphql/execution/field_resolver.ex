
defmodule GraphQL.Execution.FieldResolver do
  alias GraphQL.Execution.Resolvable

  def resolve(field_def, source, args, info) do
    # TODO: move this if statement to inside the resolvers?
    source = if !is_nil(source) && is_atom(source) do
      apply(source, :type, [])
    else
      source
    end
    Resolvable.resolve(Map.get(field_def, :resolve), source, args, info)
  end
end


