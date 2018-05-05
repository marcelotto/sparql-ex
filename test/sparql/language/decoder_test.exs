defmodule SPARQL.Language.DecoderTest do
  use ExUnit.Case

  import RDF.Sigils

  doctest SPARQL.Language

  import SPARQL.Language.Decoder, only: [decode: 1]


  test "prologue" do
    query = """
      BASE <http://exmaple.com/ns>
      PREFIX foaf: <http://xmlns.com/foaf/0.1/>
      SELECT * WHERE { ?s a ?class }
      """

    assert {:ok, %SPARQL.Query{
              base: ~I<http://exmaple.com/ns>,
              prefixes: %{"foaf" => ~I<http://xmlns.com/foaf/0.1/>},
            }} = decode(query)
  end

  describe "query form" do
    test "SELECT" do
      assert {:ok, %SPARQL.Query{form: :select}} = decode("SELECT * WHERE { ?s a ?class }")
    end

    test "ASK" do
      assert {:ok, %SPARQL.Query{form: :ask}} = decode("ASK { ?s a ?class }")
    end
  end

end