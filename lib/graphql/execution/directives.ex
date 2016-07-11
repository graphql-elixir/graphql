
defmodule GraphQL.Execution.Directives do
  alias GraphQL.Execution.Arguments

  def resolve_directive(context, directives, directive_name) do
    ast = Enum.find(directives, fn(d) -> d.name.value == Atom.to_string(directive_name) end)
    if ast do
      directive = apply(GraphQL.Type.Directives, directive_name, [])
      %{if: val} = Arguments.argument_values(directive.args, ast.arguments, context.variable_values)
      val
    else
      directive_name == :include
    end
  end
end
