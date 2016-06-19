
defprotocol GraphQL.Execution.BatchResolvable do
  @fallback_to_any true

  def group_key(batch_resolvable)

  def batch(batch_resolvable1, batch_resolvable2)

  def resolve(batch_resolvable)

  def batchable?(batch_resolvable)
end

defimpl GraphQL.Execution.BatchResolvable, for: Any do
  def group_key(batch_resolvable) do
    raise "BatchResolvable.group_key/1 not supported for type Any"
  end

  def batch(batch_resolvable1, batch_resolvable2) do
    raise "BatchResolvable.batch/2 not supported for type Any"
  end

  def resolve(batch_resolvable) do
    raise "BatchResolvable.resolve/1 not supported for type Any"
  end

  def batchable?(batch_resolvable), do: false
end

defmodule GraphQL.Execution.BatchResolvable.Group do
  alias GraphQL.Execution.BatchResolvable

  def partition(batch_resolvables) do
    Enum.reduce(batch_resolvables, %{}, fn(batch_resolvable, batches) ->
      combine_into_batch(batches, batch_resolvable)
    end) |> Map.values()
  end

  defp combine_into_batch(batches, batch_resolvable) do
    batch_key = BatchResolvable.group_key(batch_resolvable)
    if Map.has_key?(batches, batch_key) do
      %{batches | batch_key => BatchResolvable.batch(batches[batch_key], batch_resolvable)}
    else
      Map.merge(batches, %{batch_key => batch_resolvable})
    end
  end
end


