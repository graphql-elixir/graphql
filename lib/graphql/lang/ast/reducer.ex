
# Used for computing a result as a function of the an AST traversal.  The
# traditional OO Visitor pattern does not really work well in functional
# languages due to its reliance on generating side-effects.
defmodule GraphQL.Lang.AST.Reducer do

  alias GraphQL.Lang.AST.{
    Visitor,
    InitialisingVisitor,
    PostprocessingVisitor,
    Nodes
  }

  def reduce(node, visitor, accumulator) do
    accumulator = InitialisingVisitor.init(visitor, accumulator)
    accumulator = visit(node, visitor, accumulator)
    PostprocessingVisitor.finish(visitor, accumulator)
  end

  defp visit([child|rest], visitor, accumulator) do
    accumulator = visit(child, visitor, accumulator)
    visit(rest, visitor, accumulator)
  end

  defp visit([], _visitor, accumulator), do: accumulator

  defp visit(node, visitor, accumulator) do
    {next_action, accumulator} = Visitor.enter(visitor, node, accumulator) 

    accumulator = if next_action != :skip do
      visit_children(node, visitor, accumulator)
    else
      accumulator
    end

    Visitor.leave(visitor, node, accumulator)
  end

  defp visit_children(node = %{kind: kind}, visitor, accumulator) when is_atom(kind) do
    children = for child_key <- Nodes.kinds[node[:kind]], Map.has_key?(node, child_key), do: node[child_key]
    visit_each_child(children, visitor, accumulator)
  end

  defp visit_each_child([child|rest], visitor, accumulator) do
    accumulator = visit(child, visitor, accumulator)
    accumulator = visit_each_child(rest, visitor, accumulator)
    accumulator
  end

  defp visit_each_child([], _visitor, accumulator), do: accumulator
end
