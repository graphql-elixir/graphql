
alias GraphQL.Lang.AST.Visitor
alias GraphQL.Lang.AST.InitialisingVisitor
alias GraphQL.Lang.AST.PostprocessingVisitor

defmodule GraphQL.Lang.AST.CompositeVisitor do
  @moduledoc """
  A CompositeVisitor composes two Visitor implementations into a single Visitor.

  This provides the ability to chain an arbitrary number of visitors together.

  The *outer_visitor* notionally wraps the *inner_visitor*. The order of operations is thus:

  1. outer_visitor.enter
  2. inner_visitor.enter
  3. inner_visitor.leave
  4. outer_visitor.leave
  """

  defstruct outer_visitor: nil, inner_visitor: nil

  @doc """
  Composes two Visitors, returning a new one.
  """
  def compose(outer_visitor, inner_visitor) do
    %GraphQL.Lang.AST.CompositeVisitor{outer_visitor: outer_visitor, inner_visitor: inner_visitor}
  end

  @doc """
  Composes an arbitrarily long list of Visitors into a single Visitor.

  The order of the list is outer-to-inner.  The leftmost visitor will be invoked first
  upon 'enter' and last upon 'leave'.
  """
  def compose([visitor]), do: visitor
  def compose([outer_visitor|rest]), do: compose(outer_visitor, compose(rest))
end

defimpl Visitor, for: GraphQL.Lang.AST.CompositeVisitor do

  @doc """
  Invoke *enter* on the outer visitor first, passing the resulting accumulator to the *enter*
  call on the *inner* visitor.

  If either visitor's enter method returns :skip, both visitors will still be executed, but
  then execution will cease.
  """
  def enter(composite_visitor, node, accumulator) do
    {v1_next_action, v1_accumulator}
      = Visitor.enter(composite_visitor.outer_visitor, node, accumulator)
    accumulator = Map.merge(accumulator, v1_accumulator)

    if v1_next_action == :skip do
      {:skip, accumulator}
    else
      Visitor.enter(composite_visitor.inner_visitor, node, accumulator)
    end
  end

  @doc """
  Invoke *leave* on the inner visitor first, passing the resulting accumulator to the *leave*
  call on the *outer* visitor.

  If either visitor's enter method returns :skip, both visitors will still be executed, but
  then execution will cease.
  """
  def leave(composite_visitor, node, accumulator) do
    v1_accumulator = Visitor.leave(composite_visitor.inner_visitor, node, accumulator)
    v2_accumulator = Visitor.leave(composite_visitor.outer_visitor, node, Map.merge(accumulator, v1_accumulator))
    v2_accumulator
  end
end

defimpl InitialisingVisitor, for: GraphQL.Lang.AST.CompositeVisitor do
  @doc """
  Invokes *start* on the outer visitor first, then calls *start* on the inner visitor
  passing the accumulator from the *outer*.

  Returns the accumulator of the *inner* visitor.
  """
  def init(composite_visitor, accumulator) do
    accumulator = InitialisingVisitor.init(composite_visitor.outer_visitor, accumulator)
    InitialisingVisitor.init(composite_visitor.inner_visitor, accumulator)
  end
end

defimpl PostprocessingVisitor, for: GraphQL.Lang.AST.CompositeVisitor do
  @doc """
  Invokes *finish* on the inner visitor first, then calls *finish* on the outer visitor
  passing the accumulator from the *inner*.

  Returns the accumulator of the *outer* visitor.
  """
  def finish(composite_visitor, accumulator) do
    accumulator = PostprocessingVisitor.finish(composite_visitor.inner_visitor, accumulator)
    PostprocessingVisitor.finish(composite_visitor.outer_visitor, accumulator)
  end
end

