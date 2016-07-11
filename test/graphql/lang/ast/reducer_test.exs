
defmodule GraphQL.Lang.AST.ReducerTest do
  use ExUnit.Case, async: true

  alias GraphQL.Lang.Parser
  alias GraphQL.Lang.AST.Reducer
  alias GraphQL.Lang.AST.CompositeVisitor

  alias GraphQL.TestSupport.VisitorImplementations.{
    CallReverser,
    TracingVisitor,
    BalancedCallsVisitor
  }

  test "Enter and leave calls should be balanced" do
    {:ok, ast} = Parser.parse "type Person {name: String}"
    count = Reducer.reduce(ast, %BalancedCallsVisitor{}, %{count: 0})
    assert count == 0
  end

  test "All nodes are visited" do
    {:ok, ast} = Parser.parse "type Person {name: String}"

    v0 = %CallReverser{}
    v1 = %TracingVisitor{name: "Tracing Visitor"}
    composite_visitor = CompositeVisitor.compose([v0, v1])

    log = Reducer.reduce(ast, composite_visitor, %{calls: []})
    assert log == [
      "Tracing Visitor entering Document",
      "Tracing Visitor entering ObjectTypeDefinition",
      "Tracing Visitor entering Name",
      "Tracing Visitor leaving Name",
      "Tracing Visitor entering FieldDefinition",
      "Tracing Visitor entering Name",
      "Tracing Visitor leaving Name",
      "Tracing Visitor entering NamedType",
      "Tracing Visitor entering Name",
      "Tracing Visitor leaving Name",
      "Tracing Visitor leaving NamedType",
      "Tracing Visitor leaving FieldDefinition",
      "Tracing Visitor leaving ObjectTypeDefinition",
      "Tracing Visitor leaving Document"
    ]
  end
end
