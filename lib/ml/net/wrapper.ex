defmodule Ml.Net.Wrapper do
  @moduledoc false

  alias Ml.Net.InputNode
  alias Ml.Net.Neuron
  alias Ml.Net.ErrorNode

  use GenServer

  defmodule State do
    @moduledoc false
    defstruct [:x_pids, :y_pids, :b_pid, :neuron_pids, :err_pid]
  end

  # Client

  def start_link(default) do
    GenServer.start_link(__MODULE__, default)
  end

  def fit(pid, xs, ys) do
    GenServer.call(pid, {:fit, xs, ys})
  end

  def stop(pid) do
    GenServer.stop(pid)
  end

  # Server (callbacks)

  @impl true

  def init([xn, yn, [first_layer | _] = layers, a]) do
    x_pids = for _ <- 1..xn do
      {:ok, input_node} = GenServer.start_link(InputNode, first_layer)
      input_node
    end

    y_pids = for _ <- 1..yn do
      {:ok, input_node} = GenServer.start_link(InputNode, 1)
      input_node
    end

    num_of_neurons = Enum.sum(layers)
    {:ok, b_pid} = GenServer.start_link(InputNode, num_of_neurons)

    layer_last_index = length(layers) - 1

    neuron_pids = for {n, index} <- Enum.with_index(layers) do
      for _ <- 1..n do
        num_of_inputs = case index do
          0 -> xn
          _ -> Enum.at(layers, index - 1)
        end
        num_of_outputs = case index do
          ^layer_last_index -> yn
          _ -> Enum.at(layers, index + 1)
        end
        {:ok, neuron} = GenServer.start_link(Neuron, [num_of_inputs + 1, num_of_outputs], a)
        neuron
      end
    end

    {:ok, err_pid} = GenServer.start_link(ErrorNode, yn)

    for pid <- x_pids do
      InputNode.set_x_pid(pid, self())
      InputNode.set_y_pids(pid, Enum.at(neuron_pids, 0))
    end

    for pid <- y_pids do
      InputNode.set_x_pid(pid, self())
      InputNode.set_y_pids(pid, [err_pid])
    end

    for {pids, index} <- Enum.with_index(neuron_pids) do
      for pid <- pids do
        case index do
          0 ->
            Neuron.set_x_pids(pid, x_pids ++ [b_pid])
            Neuron.set_y_pids(pid, Enum.at(neuron_pids, index + 1))
          ^layer_last_index ->
            Neuron.set_x_pids(pid, Enum.at(neuron_pids, index - 1) ++ [b_pid])
            Neuron.set_y_pids(pid, [err_pid])
          _ ->
            Neuron.set_x_pids(pid, Enum.at(neuron_pids, index - 1) ++ [b_pid])
            Neuron.set_y_pids(pid, Enum.at(neuron_pids, index + 1))
        end
      end
    end

    ErrorNode.set_x_pids(err_pid, Enum.at(neuron_pids, length(layers) - 1))
    ErrorNode.set_y_pids(err_pid, y_pids)

    state = %State{x_pids: x_pids, y_pids: y_pids, b_pid: b_pid, neuron_pids: neuron_pids, err_pid: err_pid}
    {:ok, state}
  end

  @impl true

  def handle_call({:fit, xs, ys}, _from, %State{x_pids: x_pids, y_pids: y_pids, b_pid: b_pid} = state) do
    Enum.zip(x_pids, xs)
    |> Enum.each(fn {pid, x} -> send(pid, {:fire, self(), x}) end)

    Enum.zip(y_pids, ys)
    |> Enum.each(fn {pid, y} -> send(pid, {:fire, self(), y}) end)

    send(b_pid, {:fire, self(), 1.0})

    for _ <- Enum.concat([x_pids, y_pids, [b_pid]]) do
      receive do
        {:back_propagate, _, _} -> :ok
      end
    end

    {:reply, :ok, state}
  end

end
