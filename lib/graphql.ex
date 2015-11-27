defmodule GraphQL do
  @moduledoc ~S"""
  The main GraphQL module.

  The `GraphQL` module provides a
  [GraphQL](http://facebook.github.io/graphql/) implementation for Elixir.

  ## Parse a query

  Parse a GraphQL query

      iex> GraphQL.parse "{ hello }"
      {:ok, %{definitions: [
        %{kind: :OperationDefinition, loc: %{start: 0},
          operation: :query,
          selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
            selections: [
              %{kind: :Field, loc: %{start: 0}, name: "hello"}
            ]
          }}
        ],
        kind: :Document, loc: %{start: 0}
      }}

  ## Execute a query

  Execute a GraphQL query against a given schema / datastore.

      # iex> GraphQL.execute schema, "{ hello }"
      # {:ok, %{hello: "world"}}
  """

  defmodule ObjectType do
    defstruct name: "RootQueryType", description: "", fields: []
  end

  defmodule FieldDefinition do
    defstruct name: nil, type: "String", args: %{}, resolve: nil
  end

  @doc """
  Tokenize the input string into a stream of tokens.

      iex> GraphQL.tokenize("{ hello }")
      [{ :"{", 1 }, { :name, 1, 'hello' }, { :"}", 1 }]

  """
  def tokenize(input_string) when is_binary(input_string) do
    input_string |> to_char_list |> tokenize
  end

  def tokenize(input_string) do
    {:ok, tokens, _} = :graphql_lexer.string input_string
    tokens
  end

  @doc """
  Parse the input string into a Document AST.

      iex> GraphQL.parse("{ hello }")
      {:ok,
        %{definitions: [
          %{kind: :OperationDefinition, loc: %{start: 0},
            operation: :query,
            selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
              selections: [
                %{kind: :Field, loc: %{start: 0}, name: "hello"}
              ]
            }}
          ],
          kind: :Document, loc: %{start: 0}
        }
      }
  """
  def parse(input_string) when is_binary(input_string) do
    input_string |> to_char_list |> parse
  end

  def parse(input_string) do
    case input_string |> tokenize |> :graphql_parser.parse do
      {:ok, parse_result} ->
        {:ok, parse_result}
      {:error, {line_number, _, errors}} ->
        {:error, %{errors: [%{message: "GraphQL: #{errors} on line #{line_number}", line_number: line_number}]}}
    end
  end

  @doc """
  Execute a query against a schema.

      # iex> GraphQL.execute(schema, "{ hello }")
      # {:ok, %{hello: world}}
  """
  def execute(schema, document, root_value \\ %{}, variable_values \\ %{}, operation_name \\ nil) do
    context = build_execution_context(schema, document, root_value, variable_values, operation_name)
    {:ok, {data, errors}} = execute_operation(context, context.operation, root_value)
    {:ok, data}
  end

  defp build_execution_context(schema, document, root_value, variable_values, operation_name) do
    %{
      schema: schema,
      fragments: %{},
      root_value: root_value,
      operation: find_operation(document, operation_name),
      variable_values: variable_values,
      errors: []
    }
  end

  defp execute_operation(context, operation, root_value) do
    type = get_operation_root_type(context.schema, operation)
    fields = collect_fields(context, type, operation.selectionSet)
    result = case operation.operation do
      'mutation' -> execute_fields_serially(context, type, root_value, fields)
      _ -> execute_fields(context, type, root_value, fields)
    end
    {:ok, {result, nil}}
  end

  defp find_operation(document, operation_name) do
    hd(document.definitions)
  end

  defp get_operation_root_type(schema, operation) do
    schema.query
  end

  defp collect_fields(context, runtime_type, selection_set, fields \\ %{}, visited_fragment_names \\ %{}) do
    Enum.reduce selection_set[:selections], fields, fn(selection, fields) ->
      case selection do
        %{kind: :Field} -> Map.put(fields, field_entry_key(selection), [selection])
        _ -> fields
      end
    end
  end

  # source_value -> root_value?
  defp execute_fields(context, parent_type, source_value, fields) do
    Enum.reduce fields, %{}, fn({field_name, field_asts}, results) ->
      Map.put results, field_name, resolve_field(context, parent_type, source_value, field_asts)
    end
  end

  defp execute_fields_serially(context, type, root_value, fields) do
    {:error, "not yet implemented"}
  end

  defp resolve_field(context, parent_type, source, field_asts) do
    field_ast = hd(field_asts)
    field_name = field_ast.name
    field_def = field_definition(context.schema, parent_type, field_name)
    return_type = field_def.type

    resolve_fn = Map.get(field_def, :resolve, &default_resolve_fn/3)
    args = argument_values(Map.get(field_def, :args, %{}), Map.get(field_ast, :arguments, %{}), context.variable_values)
    info = %{
      field_name: field_name,
      field_asts: field_asts,
      return_type: return_type,
      parent_type: parent_type,
      schema: context.schema,
      fragments: context.fragments,
      root_value: context.root_value,
      operation: context.operation,
      variable_values: context.variable_values
    }
    result = resolve_fn.(source, args, info)
    complete_value(context, return_type, field_asts, info, result)
  end

  defp default_resolve_fn(source, _args, %{field_name: field_name}) do
    source[field_name]
  end

  # defp complete_value_catching_error(context, return_type, field_asts, info, result) do
  #   # TODO lots of error checking
  #   complete_value(context, return_type, field_asts, info, result)
  # end

  defp complete_value(context, %GraphQL.ObjectType{} = return_type, field_asts, info, result) do
    sub_field_asts = Enum.reduce field_asts, %{}, fn(field_ast, sub_field_asts) ->
      if selection_set = Map.get(field_ast, :selectionSet) do
        collect_fields(context, return_type, selection_set, sub_field_asts)
      else
        sub_field_asts
      end
    end
    execute_fields(context, return_type, result, sub_field_asts)
  end

  defp complete_value(_context, _return_type, _field_asts, _info, result) do
    result
  end

  defp field_definition(schema, parent_type, field_name) do
    # TODO deal with introspection
    parent_type.fields[String.to_atom field_name]
  end

  defp argument_values(arg_defs, arg_asts, variable_values) do
    arg_ast_map = Enum.reduce arg_asts, %{}, fn(arg_ast, result) ->
      Map.put(result, String.to_atom(arg_ast.name), arg_ast)
    end
    Enum.reduce arg_defs, %{}, fn(arg_def, result) ->
      {arg_def_name, arg_def_type} = arg_def
      if value_ast = arg_ast_map[arg_def_name] do
        Map.put result, arg_def_name, value_from_ast(value_ast, arg_def_type, variable_values)
      else
        result
      end
    end
  end

  defp value_from_ast(value_ast, type, variable_values) do
    value_ast.value.value
  end

  defp field_entry_key(field) do
    Map.get(field, :alias, field.name)
  end
end
