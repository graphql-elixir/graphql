
# A Patch represents an update to the result tree.
# It is used during batch resolution in order to update potentially multiple
# nodes in the tree with the result of execution of a BatchResolvable.
defmodule GraphQL.Execution.Patch do
  defstruct [:path, :value]

  def apply(results, patch) do
    put_in(results, patch.path, patch.value)
  end
end

