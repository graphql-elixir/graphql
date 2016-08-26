
defmodule GraphQL.TestSupport.VisitorImplementations do

  alias GraphQL.Lang.AST.Visitor
  alias GraphQL.Lang.AST.PostprocessingVisitor


  defmodule TracingVisitor do
    defstruct name: nil
  end

  defimpl Visitor, for: TracingVisitor do
    def enter(visitor, node, accumulator) do
      {:continue, %{accumulator | calls: ["#{visitor.name} entering #{node[:kind]}"] ++ accumulator[:calls]}}
    end

    def leave(visitor, node, accumulator) do
      %{accumulator | calls: ["#{visitor.name} leaving #{node[:kind]}"] ++ accumulator[:calls]}
    end
  end

  defmodule CallReverser do
    defstruct name: "call reverser"
  end

  defimpl PostprocessingVisitor, for: CallReverser do
    def finish(_visitor, accumulator) do
      Enum.reverse(accumulator[:calls])
    end
  end

  defmodule BalancedCallsVisitor do
    defstruct name: "balanced calls visitor"
  end

  defimpl Visitor, for: BalancedCallsVisitor do
    def enter(_visitor, _node, accumulator) do
      {:continue, %{accumulator | count: accumulator[:count] + 1}}
    end

    def leave(_visitor, _node, accumulator) do
      %{accumulator | count: accumulator[:count] - 1}
    end
  end

  defimpl PostprocessingVisitor, for: BalancedCallsVisitor do
    def finish(_visitor, accumulator), do: accumulator[:count]
  end
end

