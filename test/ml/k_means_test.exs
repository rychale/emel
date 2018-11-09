defmodule KMeansTest do
  use ExUnit.Case
  doctest Ml.KMeans
  import Ml.KMeans
  alias Help.Model
  alias Help.ModelTest
  alias Math.Statistics

  test "k-means on iris dataset" do
    {training_set, test_set} = "resources/datasets/iris.csv"
                               |> Model.load_dataset()
                               |> Model.training_and_test_sets(0.80)
    f = training_set
        |> Enum.map(&ModelTest.parse_flower/1)
        |> Model.normalize(["petal_length", "petal_width", "sepal_length", "sepal_width"])
        |> classifier(
             ["petal_length", "petal_width", "sepal_length", "sepal_width"],
             ["setosa", "versicolor", "virginica"]
           )
    predicted_classes = test_set
                        |> Enum.map(&ModelTest.parse_flower/1)
                        |> Model.normalize(["petal_length", "petal_width", "sepal_length", "sepal_width"])
                        |> Enum.map(fn row -> f.(row) end)
    actual_classes = Enum.map(test_set, fn %{"species" => sp} -> sp end)
    score = Statistics.similarity(predicted_classes, actual_classes)
    assert score == 0.9666666666666667
  end

end
