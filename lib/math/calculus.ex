defmodule Math.Calculus do

  @doc """
  `f(x) = 1 / (1 + e^(-x))`

  ## Examples

      iex> Math.Calculus.logistic_function(0)
      0.5

      iex> Math.Calculus.logistic_function(6)
      0.9975273768433653

      iex> Math.Calculus.logistic_function(-6)
      0.0024726231566347743

  """
  def logistic_function(x), do: 1 / (1 + :math.exp(-x))

  @doc """
  The _derivative_ of the logistic_function

  ## Examples

      iex> Math.Calculus.logistic_derivative(0)
      0.25

      iex> Math.Calculus.logistic_derivative(6)
      0.002466509291359931

      iex> Math.Calculus.logistic_derivative(-6)
      0.002466509291360048

  """
  def logistic_derivative(x), do: logistic_function(x) * (1 - logistic_function(x))

end
