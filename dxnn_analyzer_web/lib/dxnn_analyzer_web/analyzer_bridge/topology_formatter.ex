defmodule DxnnAnalyzerWeb.AnalyzerBridge.TopologyFormatter do
  @moduledoc """
  Formats topology data into graph structures for visualization.
  """

  @doc """
  Formats topology into a graph structure with nodes and edges.
  """
  def format_topology_graph({:error, reason}), do: {:error, to_string(reason)}

  def format_topology_graph(topology) when is_map(topology) do
    nodes = build_graph_nodes(topology)
    edges = build_graph_edges(topology)
    layers = organize_by_layer(topology)

    %{
      nodes: nodes,
      edges: edges,
      layers: layers,
      stats: %{
        sensor_count: length(Map.get(topology, :sensors, [])),
        neuron_count: length(Map.get(topology, :neurons, [])),
        actuator_count: length(Map.get(topology, :actuators, [])),
        connection_count: length(edges)
      }
    }
  end

  def format_topology_graph(_), do: {:error, "Invalid topology data"}

  # Private functions

  defp build_graph_nodes(topology) do
    sensors = Map.get(topology, :sensors, []) |> Enum.reject(&(&1 == :undefined))
    neurons = Map.get(topology, :neurons, []) |> Enum.reject(&(&1 == :undefined))
    actuators = Map.get(topology, :actuators, []) |> Enum.reject(&(&1 == :undefined))

    sensor_nodes = build_sensor_nodes(sensors)
    neuron_nodes = build_neuron_nodes(neurons)
    actuator_nodes = build_actuator_nodes(actuators, neuron_nodes)

    sensor_nodes ++ neuron_nodes ++ actuator_nodes
  end

  defp build_sensor_nodes(sensors) do
    Enum.map(sensors, fn sensor ->
      sensor_id = elem(sensor, 1)
      sensor_name = to_string(elem(sensor, 2))
      vl = elem(sensor, 6)

      %{
        id: inspect(sensor_id),
        type: "sensor",
        label: "#{sensor_name} #{vl}",
        short_id: extract_last_digits(sensor_id),
        name: sensor_name,
        vl: vl,
        layer: 0,
        fanout_ids: Enum.map(elem(sensor, 7), &inspect/1)
      }
    end)
  end

  defp build_neuron_nodes(neurons) do
    Enum.map(neurons, fn neuron ->
      neuron_id = elem(neuron, 1)
      layer = elem(elem(neuron_id, 0), 0)
      af = elem(neuron, 4)
      pf = elem(neuron, 5)
      aggr_f = elem(neuron, 6)
      input_idps = elem(neuron, 7)
      input_idps_modulation = elem(neuron, 8)
      output_ids = elem(neuron, 9)
      ro_ids = elem(neuron, 10)

      %{
        id: inspect(neuron_id),
        type: "neuron",
        label: extract_last_digits(neuron_id),
        short_id: extract_last_digits(neuron_id),
        af: inspect(af),
        pf: inspect(pf),
        aggr_f: inspect(aggr_f),
        layer: layer,
        input_count: length(input_idps),
        output_count: length(output_ids),
        input_ids: Enum.map(input_idps, fn {id, _weights} -> inspect(id) end),
        input_modulation_ids:
          Enum.map(input_idps_modulation, fn {id, _weights} -> inspect(id) end),
        output_ids: Enum.map(output_ids, &inspect/1),
        ro_ids: Enum.map(ro_ids, &inspect/1)
      }
    end)
  end

  defp build_actuator_nodes(actuators, neuron_nodes) do
    max_layer =
      case neuron_nodes do
        [] -> 1
        _ -> Enum.max_by(neuron_nodes, & &1.layer).layer
      end

    Enum.map(actuators, fn actuator ->
      actuator_id = elem(actuator, 1)
      actuator_name = to_string(elem(actuator, 2))
      vl = elem(actuator, 6)

      %{
        id: inspect(actuator_id),
        type: "actuator",
        label: "#{actuator_name} #{vl}",
        short_id: extract_last_digits(actuator_id),
        name: actuator_name,
        vl: vl,
        layer: max_layer + 1,
        fanin_ids: Enum.map(elem(actuator, 7), &inspect/1)
      }
    end)
  end

  defp build_graph_edges(topology) do
    neurons = Map.get(topology, :neurons, []) |> Enum.reject(&(&1 == :undefined))

    input_edges = build_input_edges(neurons)
    recurrent_edges = build_recurrent_edges(neurons)

    all_edges = input_edges ++ recurrent_edges
    Enum.uniq_by(all_edges, fn edge -> {edge.source, edge.target} end)
  end

  defp build_input_edges(neurons) do
    Enum.flat_map(neurons, fn neuron ->
      neuron_id = elem(neuron, 1)
      input_idps = elem(neuron, 7)

      Enum.map(input_idps, fn {input_id, weights} ->
        weight_list = normalize_weights(weights)
        source_layer = get_layer_index(input_id)
        target_layer = get_layer_index(neuron_id)
        is_recurrent = source_layer >= target_layer

        %{
          source: inspect(input_id),
          target: inspect(neuron_id),
          weight: length(weight_list),
          weights: Enum.take(weight_list, 5),
          recurrent: is_recurrent
        }
      end)
    end)
  end

  defp build_recurrent_edges(neurons) do
    Enum.flat_map(neurons, fn neuron ->
      neuron_id = elem(neuron, 1)
      ro_ids = elem(neuron, 10)

      Enum.map(ro_ids, fn target_id ->
        %{
          source: inspect(neuron_id),
          target: inspect(target_id),
          weight: 1,
          weights: [],
          recurrent: true
        }
      end)
    end)
  end

  defp normalize_weights(weights) do
    cond do
      is_list(weights) ->
        Enum.map(weights, fn w ->
          if is_tuple(w), do: elem(w, 0), else: w
        end)

      is_tuple(weights) ->
        [elem(weights, 0)]

      is_number(weights) ->
        [weights]

      true ->
        []
    end
  end

  defp organize_by_layer(topology) do
    neurons = Map.get(topology, :neurons, []) |> Enum.reject(&(&1 == :undefined))

    neurons
    |> Enum.group_by(fn neuron ->
      neuron_id = elem(neuron, 1)
      elem(elem(neuron_id, 0), 0)
    end)
    |> Enum.map(fn {layer, layer_neurons} ->
      %{
        layer: layer,
        neuron_count: length(layer_neurons),
        neurons: Enum.map(layer_neurons, fn n -> inspect(elem(n, 1)) end)
      }
    end)
    |> Enum.sort_by(& &1.layer)
  end

  defp extract_last_digits(id) when is_tuple(id) do
    case elem(id, 0) do
      {_layer, timestamp} when is_float(timestamp) ->
        timestamp_str = Float.to_string(timestamp)

        decimal_part =
          timestamp_str
          |> String.split("e")
          |> List.first()
          |> String.replace(".", "")

        String.slice(decimal_part, -4..-1) || "0000"

      _ ->
        "0000"
    end
  end

  defp extract_last_digits(_), do: "0000"

  defp get_layer_index(id) when is_tuple(id) do
    case elem(id, 0) do
      {layer, _} when is_integer(layer) -> layer
      _ -> 0
    end
  end

  defp get_layer_index(_), do: 0
end
