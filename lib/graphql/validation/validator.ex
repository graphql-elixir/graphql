
defmodule GraphQL.Validation.Validator do

  alias GraphQL.Lang.AST.{
    CompositeVisitor,
    ParallelVisitor,
    TypeInfoVisitor,
    TypeInfo,
    DocumentInfo,
    Reducer
  }

  alias GraphQL.Validation.Rules

  @doc """
  Runs validations against the document with all known validation rules.
  """
  def validate(schema, document) do
    validate_with_rules(schema, document, Rules.all)   
  end

  @doc """
  Short circuits the validations entirely when there are no rules specified.
  This is useful for examining the performance impact of validations.
  """
  def validate_with_rules(schema, document, rules) when length(rules) == 0, do: :ok

  @doc """
  For performance testing with a single rule, the overhead of the ParallelVisitor
  can be removed.
  """
  def validate_with_rules(schema, document, [rule|[]] = rules) when length(rules) == 1 do
    validation_pipeline = CompositeVisitor.compose([
      %TypeInfoVisitor{},
      rule 
    ])
    result = Reducer.reduce(document, validation_pipeline, %{
      type_info: %TypeInfo{schema: schema},
      document_info: DocumentInfo.new(schema, document),
      document: document,
      validation_errors: []
    })
    errors = result[:validation_errors]
    if length(errors) > 0 do
      {:error, Enum.reverse(errors)}
    else
      :ok
    end
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
      document_info: DocumentInfo.new(schema, document),
      document: document,
      validation_errors: []
    })
    errors = result[:validation_errors]
    if length(errors) > 0 do
      {:error, Enum.reverse(errors)}
    else
      :ok
    end
  end
end
