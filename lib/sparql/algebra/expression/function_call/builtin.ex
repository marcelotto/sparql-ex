defmodule SPARQL.Algebra.FunctionCall.Builtin do
  defstruct name: nil,
            arguments: []

  alias SPARQL.Algebra.FunctionCall
  alias SPARQL.Functions.Builtins


  @doc """
  Invokes a SPARQL builtin function.

  For most functions this is done by delegating to `SPARQL.Functions.Builtins.call/2`.
  However, some functions have special "functional forms" which have different
  evaluation rules. All of these are implemented here directly.

  see <https://www.w3.org/TR/sparql11-query/#invocation>
  """
  def invoke(name, arguments, data)

  def invoke(:&&, [left, right], data) do
    case evaluate_to_ebv(left, data) do
      %RDF.Literal{value: false} ->
        RDF.false

      %RDF.Literal{value: true}  ->
        case evaluate_to_ebv(right, data) do
          %RDF.Literal{value: true}  -> RDF.true
          %RDF.Literal{value: false} -> RDF.false
          nil                        -> :error
        end

      nil ->
        if match?(%RDF.Literal{value: false}, evaluate_to_ebv(right, data)) do
          RDF.false
        else
          :error
        end
    end
  end

  def invoke(:||, [left, right], data) do
    case evaluate_to_ebv(left, data) do
      %RDF.Literal{value: true} ->
        RDF.true

      %RDF.Literal{value: false}  ->
        case evaluate_to_ebv(right, data) do
          %RDF.Literal{value: true}  -> RDF.true
          %RDF.Literal{value: false} -> RDF.false
          nil                        -> :error
        end

      nil ->
        if match?(%RDF.Literal{value: true}, evaluate_to_ebv(right, data)) do
          RDF.true
        else
          :error
        end
    end
  end

  def invoke(:IF, [cond_expression, then_expression, else_expression], data) do
    case evaluate_to_ebv(cond_expression, data) do
      %RDF.Literal{value: true}  -> FunctionCall.evaluate_argument(then_expression, data)
      %RDF.Literal{value: false} -> FunctionCall.evaluate_argument(else_expression, data)
      nil                        -> :error
    end
  end

  def invoke(:COALESCE, expressions, data) do
    expressions
    |> Stream.map(&(FunctionCall.evaluate_argument(&1, data)))
    |> Enum.find(:error, &(&1 != :error))
  end

  def invoke(:IN, [lhs, expression_list], data) do
    case FunctionCall.evaluate_argument(lhs, data) do
      :error -> :error
      value ->
        expression_list
        |> Enum.reduce_while(RDF.false, fn expression, acc ->
             case FunctionCall.evaluate_argument(expression, data) do
               :error -> {:cont, :error}
               result ->
                 case RDF.Term.equal_value?(value, result) do
                   true  -> {:halt, RDF.true}
                   false -> {:cont, acc}
                   _     -> {:cont, :error}
                 end
             end
           end)
    end
  end

  def invoke(:NOT_IN, [lhs, expression_list], data) do
    case FunctionCall.evaluate_argument(lhs, data) do
      :error -> :error
      value ->
        expression_list
        |> Enum.reduce_while(RDF.true, fn expression, acc ->
             case FunctionCall.evaluate_argument(expression, data) do
               :error -> {:cont, :error}
               result ->
                 case RDF.Term.equal_value?(value, result) do
                   true  -> {:halt, RDF.false}
                   false -> {:cont, acc}
                   _     -> {:cont, :error}
                 end
             end
           end)
    end
  end

  def invoke(name, arguments, data) do
    with {:ok, evaluated_arguments} <-
            FunctionCall.evaluate_arguments(arguments, data)
    do
      Builtins.call(name, evaluated_arguments)
    end
  end


  defp evaluate_to_ebv(expr, data) do
    expr
    |> FunctionCall.evaluate_argument(data)
    |> RDF.Boolean.ebv()
  end


  defimpl SPARQL.Algebra.Expression do
    def evaluate(%FunctionCall.Builtin{name: name, arguments: arguments}, data) do
      FunctionCall.Builtin.invoke(name, arguments, data)
    end

    def variables(function_call) do
      # TODO: return used and/or introduced variables???
    end
  end

end