
defmodule GraphQL.Validation.Validator do

  alias GraphQL.Lang.Parser
  alias GraphQL.Lang.AST.CompositeVisitor
  alias GraphQL.Lang.AST.ParallelVisitor
  alias GraphQL.Lang.AST.TypeInfoVisitor
  alias GraphQL.Lang.AST.TypeInfo
  alias GraphQL.Lang.AST.Reducer
  alias GraphQL.Validation.Rules

  @doc """
  Runs validations against the document with all known validation rules.
  """
  def validate(schema, document) do
    validate_with_rules(schema, document, Rules.all)   
  end

  @doc """
  Runs validations against the document with only the specified rules.
  """
  def validate_with_rules(schema, document, rules) do
    validation_pipeline = CompositeVisitor.compose([
      %TypeInfoVisitor{},
      %ParallelVisitor{visitors: rules}
    ])
    result = Reducer.reduce(document, validation_pipeline, %{
      type_info: %TypeInfo{schema: schema},
      validation_errors: []
    })
    errors = result[:validation_errors]
    if length(errors) > 0 do
      {:error, errors}
    else
      :ok
    end
  end
end
