defmodule SPARQL.Processor.FilterTest do
  use SPARQL.Test.Case

  import SPARQL.Processor, only: [query: 2]

  @example_graph_with_literals Graph.new([
      {EX.s1, EX.p1, 1},
      {EX.s1, EX.p2, 2},
      {EX.s3, EX.p3, "3"},
      {EX.s4, EX.p4, true},
      {EX.s5, EX.p4, false},
      {EX.s6, EX.p3, "Foo"},
      {EX.s6, EX.p3, ""},
      {EX.s7, EX.p3, RDF.date("2010-01-01")},
    ])

  test "simple comparison" do
    assert query(@example_graph_with_literals, """
      SELECT ?s
      WHERE {
        ?s ?p ?o
        FILTER(?o = 1)
      }
      """) ==
      %Query.Result{
        variables: ~w[s],
        results: [%{"s" => ~I<http://example.org/s1>}]}
  end

  test "multiple filters" do
    assert query(@example_graph_with_literals, """
      SELECT ?p
      WHERE {
        ?s ?p ?o
        FILTER(?s = <#{EX.s1}>)
        FILTER(?o = 1)
      }
      """) ==
      %Query.Result{
        variables: ~w[p],
        results: [%{"p" => ~I<http://example.org/p1>}]}
  end

  test "nested function calls" do
    assert query(@example_graph_with_literals, """
      SELECT ?s
      WHERE {
        ?s ?p ?o
        FILTER(ucase(str(?o)) = "FOO")
      }
      """) ==
      %Query.Result{
        variables: ~w[s],
        results: [%{"s" => ~I<http://example.org/s6>}]}
  end

end