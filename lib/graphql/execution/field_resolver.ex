
defmodule GraphQL.Execution.FieldResolver do
  alias GraphQL.Execution.Resolvable

  def resolve(field_def, source, args, info) do
    Resolvable.resolve(Map.get(field_def, :resolve), deref_source(source), args, info)
  end

  defp deref_source(nil), do: nil
  defp deref_source(source) when is_atom(source) do
    apply(source, :type, [])
  end
  defp deref_source(source), do: source
end


