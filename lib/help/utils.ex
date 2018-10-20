defmodule Help.Utils do
  @moduledoc false

  defmodule Pair do
    @enforce_keys [:first, :second]
    defstruct [:first, :second]
  end

  defmodule TreeNode do
    @enforce_keys [:content, :children]
    defstruct [:content, :children]
  end

  def pretty_tree(%TreeNode{content: content, children: []}), do: content
  def pretty_tree(%TreeNode{content: content, children: children}), do: {content, Enum.map(children, &pretty_tree/1)}


  @doc ~S"""
  The base `b` _logarithm_ of `x`.

    iex> Help.Utils.log(1.82, 10.0)
    0.2600713879850748

  """
  def log(x, b), do: :math.log(x) / :math.log(b)

  def identity(x), do: x

  @doc ~S"""
  The list of all indices of `ls`.

  ## Examples

      iex> Help.Utils.indices([])
      []

      iex> Help.Utils.indices([3, 7, 9])
      [0, 1, 2]

      iex> Help.Utils.indices(["b", "c", "d", "a", "e"])
      [0, 1, 2, 3, 4]

  """
  def indices([]), do: []
  def indices(ls), do: Enum.map(0 .. length(ls) - 1, &identity/1)

end
