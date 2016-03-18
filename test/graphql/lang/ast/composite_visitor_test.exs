
defmodule GraphQL.Lang.AST.CompositeVisitorTest do
  use ExUnit.Case, async: true

  alias GraphQL.Lang.Parser
  alias GraphQL.Lang.AST.Reducer
  alias GraphQL.Lang.AST.Visitor
  alias GraphQL.Lang.AST.CompositeVisitor
  alias GraphQL.Lang.AST.PostprocessingVisitor

  defmodule TracingVisitor do
    defstruct name: nil
  end

  defimpl Visitor, for: TracingVisitor do
    def enter(visitor, node, accumulator) do
      {:continue, %{accumulator | calls: ["#{visitor.name} entering #{node[:kind]}"] ++ accumulator[:calls]}}
    end

    def leave(visitor, node, accumulator) do
      {:continue, %{accumulator | calls: ["#{visitor.name} leaving #{node[:kind]}"] ++ accumulator[:calls]}}
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
  
  test "Composed Visitors are called in the correct order" do
    v0 = %CallReverser{}
    v1 = %TracingVisitor{name: "v1"}
    v2 = %TracingVisitor{name: "v2"}
    v3 = %TracingVisitor{name: "v3"}
    composite_visitor = CompositeVisitor.compose([v0, v1, v2, v3])
    {:ok, ast} = Parser.parse "type Person {name: String}"
    calls = Reducer.reduce(ast, composite_visitor, %{calls: []})
    assert calls == [
      "v1 entering Document", "v2 entering Document", "v3 entering Document",
      "v1 entering ObjectTypeDefinition", "v2 entering ObjectTypeDefinition",
      "v3 entering ObjectTypeDefinition", "v1 entering Name",
      "v2 entering Name", "v3 entering Name", "v3 leaving Name",
      "v2 leaving Name", "v1 leaving Name", "v1 entering FieldDefinition",
      "v2 entering FieldDefinition", "v3 entering FieldDefinition",
      "v1 entering Name", "v2 entering Name", "v3 entering Name",
      "v3 leaving Name", "v2 leaving Name", "v1 leaving Name",
      "v1 entering NamedType", "v2 entering NamedType", "v3 entering NamedType",
      "v1 entering Name", "v2 entering Name", "v3 entering Name",
      "v3 leaving Name", "v2 leaving Name", "v1 leaving Name",
      "v3 leaving NamedType", "v2 leaving NamedType", "v1 leaving NamedType",
      "v3 leaving FieldDefinition", "v2 leaving FieldDefinition",
      "v1 leaving FieldDefinition", "v3 leaving ObjectTypeDefinition",
      "v2 leaving ObjectTypeDefinition", "v1 leaving ObjectTypeDefinition",
      "v3 leaving Document", "v2 leaving Document", "v1 leaving Document"
    ]
  end
end


