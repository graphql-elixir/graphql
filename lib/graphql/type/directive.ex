
defmodule GraphQL.Type.Directive do
  @moduledoc """
  # Options for implementing directives

  ## Option 1

      defmodule GraphQL.Type.Directives do
        def directives do
          %{
            skip: %Directive{}
            include: %Directive{}
            deprecated: %Directive{}
          }
        end
      end

  ## Option 2

      defmodule GraphQL.Type.Directives do
        def skip do
          %Directive{}
        end
      end

  ## Option 3

      defmodule GraphQL.Type.Directives.Skip do
        def directive do
          %Directive{
          }
        end
      end

  ## Option 4

      @directive Deprecated, %Directive{ ... }
      @directive Include, %Directive{ ... }
      @directive Skip, %Directive{ ... }

  Going with option 2 for now,
  but this doesn't easily support external custom extension.
  """

  defstruct name: "Directive", description: nil, locations: [], args: %{}
end

defmodule GraphQL.Type.Directives do
  def include do
    %Directive{
      name: "include",
      description: """
      Directs the executor to include this field or fragment
      only when the `if` argument is true.
      """,
      locations: [:Field, :FragmentSpread, :InlineFragment],
      args: %{
        if: %{
          type: %NonNull{ofType: %Boolean{}},
          description: "Included when true."
        }
      }
    }
  end

  def skip do
    %Directive{
      name: "skip",
      description: """
      Directs the executor to skip this field or fragment
      only when the `if` argument is true.
      """,
      locations: [:Field, :FragmentSpread, :InlineFragment],
      args: %{
        if: %{
          type: %NonNull{ofType: %Boolean{}},
          description: "Skipped when true."
        }
      }
    }
  end

  def deprecated do
    %Directive{
      name: "skip",
      description: """
      Marks an element of a GraphQL schema as no longer supported.
      """,
      locations: [:FieldDefinition, :EnumValue],
      args: %{
        reason: %{
          type: %String{},
          description: """
          Explains why this element was deprecated, usually also including a
          suggestion for how to access supported similar data. Formatted
          in [Markdown](https://daringfireball.net/projects/markdown/).
          """,
          defaultValue: "No longer supported"
        }
      }
    }
  end
end
