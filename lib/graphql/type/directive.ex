defmodule GraphQL.Type.Directive do
  @moduledoc """
  Directives currently supported are @skip and @include
  """
  defstruct name: "Directive", description: nil, locations: [], args: %{}
end

defmodule GraphQL.Type.Directives do
  alias GraphQL.Type.{Directive, Boolean, NonNull, String}

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
          description: "Included when true.",
          defaultValue: true
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
          description: "Skipped when true.",
          defaultValue: false
        }
      }
    }
  end

  def deprecated do
    %Directive{
      name: "deprecated",
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
