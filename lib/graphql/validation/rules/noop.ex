
defmodule GraphQL.Validation.Rules.Noop do

  alias GraphQL.Lang.AST.Visitor

  defstruct name: "Noop"

  defimpl Visitor do
    def enter(_visitor, _node, accumulator), do: {:continue, accumulator}
    def leave(_visitor, _node, accumulator), do: {:continue, accumulator}
  end
end
