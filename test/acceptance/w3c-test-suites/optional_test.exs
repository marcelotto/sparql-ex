defmodule SPARQL.W3C.TestSuite.OptionalTest do
  @moduledoc """
  The W3C SPARQL 1.0 algebra test cases for optional graph patterns.

  <https://www.w3.org/2001/sw/DataAccess/tests/data-r2/optional/>
  """

  use SPARQL.W3C.TestSuite.Case, async: false

  @test_suite {"1.0", "optional"}
  @manifest_graph TestSuite.manifest_graph(@test_suite)

  TestSuite.test_cases(@test_suite, MF.QueryEvaluationTest)
  |> Enum.each(fn test_case ->
       [
         "dawg-union-001",
         "dawg-optional-complex-1",
       ]
       |> Enum.each(fn test_subject ->
         if test_case.subject |> to_string() |> String.ends_with?(test_subject),
            do: @tag skip: "TODO: UNION"
       end)

       [
         "dawg-optional-complex-2",
         "dawg-optional-complex-3",
         "dawg-optional-complex-4",
       ]
       |> Enum.each(fn test_subject ->
         if test_case.subject |> to_string() |> String.ends_with?(test_subject),
            do: @tag skip: "TODO: GRAPH"
       end)

       @tag test_case: test_case
       test TestSuite.test_title(test_case), %{test_case: test_case} do
         assert_query_evaluation_case_result(test_case, @manifest_graph)
       end
     end)
end
