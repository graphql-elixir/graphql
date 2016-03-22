
Code.require_file "../../../support/validations.exs", __DIR__

defmodule GraphQL.Validation.Rules.FieldOnCorrectTypeTest do
  use ExUnit.Case, async: true

  import ValidationsSupport

  alias GraphQL.Validation.Rules.FieldsOnCorrectType, as: Rule

  test "Object field selection" do
    assert_passes_rule(
      """ 
        fragment objectFieldSelection on Dog {
          __typename
          name
        }
      """,
      %Rule{}
    )
  end

  test "Aliased object field selection" do
    assert_passes_rule(
      """ 
        fragment aliasedObjectFieldSelection on Dog {
          tn : __typename
          otherName : name
        }
      """,
      %Rule{}
    )
  end

  test "Interface field selection" do
    assert_passes_rule(
      """ 
        fragment interfaceFieldSelection on Pet {
          __typename
          name
        }
      """,
      %Rule{}
    )
  end

  test "Aliased interface field selection" do
    assert_passes_rule(
      """ 
        fragment interfaceFieldSelection on Pet {
          otherName : name
        }
      """,
      %Rule{}
    )
  end

  test "Lying alias selection" do
    assert_passes_rule(
      """ 
        fragment lyingAliasSelection on Dog {
          name : nickname
        }
      """,
      %Rule{}
    )
  end

  test "Ignores fields on unknown type" do
    assert_passes_rule(
      """ 
        fragment unknownSelection on UnknownType {
          unknownField
        }
      """,
      %Rule{}
    )
  end

  test "reports errors when type is known again" do
    assert_fails_rule(
      """ 
        fragment typeKnownAgain on Pet {
          unknown_pet_field {
            ... on Cat {
              unknown_cat_field
            }
          }
        }
      """,
      %Rule{}
    )
  end

  test "Field not defined on fragment" do
    assert_fails_rule(
      """
        fragment fieldNotDefined on Dog {
          meowVolume
        }
      """,
      %Rule{},
      ["Cannot query field \"meowVolume\" on type \"Dog\"."]
    )
  end

  test "Ignores deeply unknown field" do
    assert_fails_rule(
      """
        fragment deepFieldNotDefined on Dog {
          unknown_field {
            deeper_unknown_field
          }
        }
      """,
      %Rule{}, 
      ["Cannot query field \"unknown_field\" on type \"Dog\"."]
    )
  end

  test "Sub-field not defined" do
    assert_fails_rule(
      """
       fragment subFieldNotDefined on Human {
         pets {
           unknown_field
         }
       }
      """,
      %Rule{},
      ["Cannot query field \"unknown_field\" on type \"Pet\"."]
    )
  end

  test "Field not defined on inline fragment" do
    assert_fails_rule(
      """
       fragment fieldNotDefined on Pet {
         ... on Dog {
           meowVolume
         }
       },
      """,
      %Rule{},
      ["Cannot query field \"meowVolume\" on type \"Dog\"."]
    )
  end

  test "Aliased field target not defined" do
    assert_fails_rule(
      """
        fragment aliasedFieldTargetNotDefined on Dog {
          volume : mooVolume
        },
      """,
      %Rule{},
      ["Cannot query field \"mooVolume\" on type \"Dog\"."]
    )
  end

  test "Aliased lying field target not defined" do
    assert_fails_rule(
      """
        fragment aliasedLyingFieldTargetNotDefined on Dog {
          barkVolume : kawVolume
        },
      """,
      %Rule{},
      ["Cannot query field \"kawVolume\" on type \"Dog\"."]
    )
  end

  test "Not defined on interface" do
    assert_fails_rule(
      """
        fragment notDefinedOnInterface on Pet {
          tailLength
        },
      """,
      %Rule{},
      ["Cannot query field \"tailLength\" on type \"Pet\"."]
    )
  end

  test "Defined on implementors but not on interface" do
    assert_fails_rule(
      """
        fragment definedOnImplementorsButNotInterface on Pet {
          nickname
        },
      """,
      %Rule{},
      [
        "Cannot query field \"nickname\" on type \"Pet\". " <>
        "However, this field exists on \"Cat\", \"Dog\". " <> 
        "Perhaps you meant to use an inline fragment?"
      ]
    )
  end

  test "Meta field selection on union" do
    assert_passes_rule(
      """
        fragment directFieldSelectionOnUnion on CatOrDog {
          __typename
        }
      """,
      %Rule{}
    )
  end

  test "Direct field selection on union" do
    assert_fails_rule(
      """
        fragment directFieldSelectionOnUnion on CatOrDog {
          directField
        },
      """,
      %Rule{},
      ["Cannot query field \"directField\" on type \"CatOrDog\"."]
    )
  end

  test "Defined on implementors queried on union" do
    assert_fails_rule(
      """
       fragment definedOnImplementorsQueriedOnUnion on CatOrDog {
         name
       },
      """,
      %Rule{},
      [
        "Cannot query field \"name\" on type \"CatOrDog\". " <>
        "However, this field exists on \"Canine\", \"Cat\", " <>
        "\"Dog\", \"Being\", \"Pet\". Perhaps you meant to use " <>
        "an inline fragment?"
      ]
    )
  end

  test "valid field in inline fragment" do
    assert_passes_rule(
      """
        fragment objectFieldSelection on Pet {
          ... on Dog {
            name
          }
          ... {
            name
          }
        }
      """,
      %Rule{}
    )
  end

end
