defmodule Emel.Ml.KMeans do
  @moduledoc """
  Aims to partition n _observations_ into k _clusters_
  in which each _observation_ belongs to the _cluster_ with the nearest _mean_.

  """
  alias Emel.Help.Utils
  alias Emel.Math.Geometry

  defp point_groups(points, centroids) do
    points
    |> Enum.group_by(fn {p, _p_index} -> Geometry.nearest_neighbor(p, centroids) end, fn {_p, _p_index} = p -> p end)
    |> Enum.sort_by(fn {k, _} -> k end)
  end

  defp iterate(clusters) do
    groups = Enum.map(clusters, fn {_, v} -> Enum.map(v, fn {p, _p_index} -> p end) end)
    old_centroids = Enum.map(clusters, fn {v, _} -> v end)
    new_centroids = groups
                    |> Enum.map(&Geometry.centroid/1)
                    |> Enum.sort()
    case new_centroids do
      ^old_centroids ->
        clusters
      _ ->
        Enum.map(clusters, fn {_, v} -> v end)
        |> Enum.concat
        |> point_groups(new_centroids)
        |> iterate()
    end
  end

  @doc """
  `points` partitioned into `k` _clusters_ in which each _point_ belongs to the _cluster_ with the nearest _mean_.

  ## Examples

      iex> Emel.Ml.KMeans.clusters([[1.0, 1.0],
      ...>                          [2.0, 1.0],
      ...>                          [4.0, 3.0],
      ...>                          [5.0, 4.0]],
      ...>                          2)
      [[{[1.0, 1.0], 0}, {[2.0, 1.0], 1}],
       [{[4.0, 3.0], 2}, {[5.0, 4.0], 3}]]

      iex> Emel.Ml.KMeans.clusters([[0.0, 0.0],
      ...>                          [4.0, 4.0],
      ...>                          [9.0, 9.0],
      ...>                          [4.3, 4.3],
      ...>                          [9.9, 9.9],
      ...>                          [4.4, 4.4],
      ...>                          [0.1, 0.1]],
      ...>                          3)
      [
        [
          {[0.0, 0.0], 0},
          {[4.0, 4.0], 1},
          {[4.3, 4.3], 3},
          {[4.4, 4.4], 5},
          {[0.1, 0.1], 6}
        ],
        [{[9.0, 9.0], 2}],
        [{[9.9, 9.9], 4}]
      ]

  """
  def clusters(_, k) when k <= 0, do: raise "K should be positive"
  def clusters(points, k) when k > length(points), do: raise "K should be less or equal to the number of points"
  def clusters(points, k) do
    centroids = points
                |> Enum.shuffle()
                |> Enum.uniq()
                |> Enum.take(k)
    points
    |> Enum.with_index
    |> point_groups(centroids)
    |> iterate()
    |> Enum.map(fn {_, v} -> v end)
  end

  @doc """
  Returns the function that classifies an item by identifying the _cluster_ it belongs to.

  ## Examples

      iex> f = Emel.Ml.KMeans.classifier([%{x1: 1.0, x2: 1.0},
      ...>                                %{x1: 2.0, x2: 1.0},
      ...>                                %{x1: 4.0, x2: 3.0},
      ...>                                %{x1: 5.0, x2: 4.0}],
      ...>                                [:x1, :x2],
      ...>                                ["0", "1"])
      ...> f.(%{x1: 1.5, x2: 1.5})
      "0"

  """
  def classifier(dataset, continuous_attributes, classes) do
    n = length(classes)
    centroids = dataset
                |> Enum.map(fn row -> Utils.map_vals(row, continuous_attributes) end)
                |> clusters(n)
		|> Enum.map(fn cluster -> Enum.map(cluster, fn {p, _p_index} -> p end) end)
                |> Enum.map(&Geometry.centroid/1)
                |> Enum.sort_by(&Geometry.magnitude/1)
    class_by_centroid = Utils.vals_map(centroids, classes)
    fn item ->
      selected_centroid = item
                          |> Utils.map_vals(continuous_attributes)
                          |> Geometry.nearest_neighbor(centroids)
      class_by_centroid[selected_centroid]
    end
  end

end
