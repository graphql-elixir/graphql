
defmodule GraphQL.Validation.Rules.UniqueOperationNames do

  alias GraphQL.Lang.AST.{Visitor, InitialisingVisitor}
  import GraphQL.Validation

  defstruct name: "UniqueOperationNames"

  defimpl InitialisingVisitor do
    def init(_visitor, accumulator) do
      Map.merge(%{operation_names: %{}}, accumulator)
    end
  end

  defimpl Visitor do
    def enter(_visitor, %{kind: :OperationDefinition, name: %{value: _} = op_name}, accumulator) do
      accumulator = if seen_operation?(accumulator, op_name) do
        report_error(accumulator, duplicate_operation_message(op_name))
      else
        mark_as_seen(accumulator, op_name)
      end
      {:continue, accumulator}
    end

    def enter(_visitor, _node, accumulator), do: {:continue, accumulator}

    def leave(_visitor, _node, accumulator), do: {:continue, accumulator}

    defp duplicate_operation_message(op_name) do
      "There can only be one operation named '#{op_name.value}'."
    end

    defp seen_operation?(accumulator, op_name) do
      Map.has_key?(accumulator[:operation_names], op_name.value)
    end

    defp mark_as_seen(accumulator, op_name) do
      put_in(accumulator[:operation_names][op_name.value], true)
    end
  end
end
