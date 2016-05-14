
defmodule GraphQL.Execution.FieldResolver do
  alias GraphQL.Execution.Resolvable

  def resolve(field_def, source, args, context, info) do
    Resolvable.resolve(
      Map.get(field_def, :resolve),
      unwrap_type(source),
      args,
      context,
      info
    )
  end

  # FIXME: this `unwrap_type` logic is duplicated in a few places.
  defp unwrap_type(nil), do: nil
  defp unwrap_type(source) when is_atom(source) do
    source.type
  end
  defp unwrap_type(source), do: source
end


