
defmodule GraphQL.Validation.Rules.UniqueOperationNames do

  alias GraphQL.Lang.AST.Visitor
  alias GraphQL.Lang.AST.InitialisingVisitor

  defstruct name: "UniqueOperationNames"

  defimpl InitialisingVisitor do
    def init(_visitor, accumulator) do
      Map.merge(%{operation_names: %{}}, accumulator)
    end
  end

  defimpl Visitor do
    def enter(_visitor, node, accumulator) do
      if node.kind == :OperationDefinition && Map.has_key?(node, :name) do
        op_name = node.name
        if op_name.value do
          if accumulator[:operation_names][op_name.value] do
            accumulator = put_in(
              accumulator[:validation_errors],
              [duplicate_operation_message(op_name)] ++ accumulator[:validation_errors]
            )
          else
            accumulator = put_in(accumulator[:operation_names][op_name.value], true)
          end
        end
      end
      {:continue, accumulator}
    end

    def leave(_visitor, _node, accumulator) do
      {:continue, accumulator}
    end

    defp duplicate_operation_message(op_name) do
      "There can only be one operation named '#{op_name.value}'."
    end
  end
end
