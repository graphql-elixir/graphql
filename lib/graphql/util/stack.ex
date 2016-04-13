defmodule GraphQL.Util.Stack do
  @moduledoc ~S"""
  A Stack implementation. *push* and *pop* return a new Stack.
  *peek* returns the top element.
  """

  alias GraphQL.Util.Stack 

  defstruct elements: []

  def push(stack, node) do
    %Stack{stack | elements: [node] ++ stack.elements}
  end

  def pop(stack) do
    case stack.elements do
      [_|rest] -> %Stack{stack | elements: rest}
      [] -> nil
    end
  end

  def peek(stack) do
    case stack.elements do
      [node|_] -> node
      [] -> nil
    end
  end
  
  def length(stack), do: Kernel.length(stack.elements)
end
