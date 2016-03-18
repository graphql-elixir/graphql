
defmodule GraphQL.Lang.AST.ReducerTest do
  use ExUnit.Case, async: true

  alias GraphQL.Lang.Parser
  alias GraphQL.Lang.AST.Reducer
  alias GraphQL.Lang.AST.Visitor
  alias GraphQL.Lang.AST.PostprocessingVisitor

  defmodule TracingVisitor do
    defstruct name: "logging visitor"
  end

  defimpl Visitor, for: TracingVisitor do
    def enter(_visitor, node, accumulator) do
      {:continue, Map.merge(accumulator, %{calls: ["Entering: #{node[:kind]}"] ++ accumulator[:calls]})}
    end

    def leave(_visitor, node, accumulator) do
      {:continue, Map.merge(accumulator, %{calls: ["Leaving: #{node[:kind]}"] ++ accumulator[:calls]})}
    end
  end

  defimpl PostprocessingVisitor, for: TracingVisitor do
    def finish(_visitor, accumulator) do
      Enum.reverse accumulator[:calls]
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
      {:continue, %{accumulator | count: accumulator[:count] - 1}}
    end
  end

  defimpl PostprocessingVisitor, for: BalancedCallsVisitor do
    def finish(_visitor, accumulator), do: accumulator[:count]
  end

  test "Enter and leave calls should be balanced" do
    {:ok, ast} = Parser.parse "type Person {name: String}"
    count = Reducer.reduce(ast, %BalancedCallsVisitor{}, %{count: 0})
    assert count == 0
  end

  test "All nodes are visited" do
    {:ok, ast} = Parser.parse "type Person {name: String}"
    log = Reducer.reduce(ast, %TracingVisitor{}, %{calls: []})
    assert log == [
      "Entering: Document",
      "Entering: ObjectTypeDefinition",
      "Entering: Name",
      "Leaving: Name",
      "Entering: FieldDefinition",
      "Entering: Name",
      "Leaving: Name",
      "Entering: NamedType",
      "Entering: Name",
      "Leaving: Name",
      "Leaving: NamedType",
      "Leaving: FieldDefinition",
      "Leaving: ObjectTypeDefinition",
      "Leaving: Document"
    ]
  end
end
