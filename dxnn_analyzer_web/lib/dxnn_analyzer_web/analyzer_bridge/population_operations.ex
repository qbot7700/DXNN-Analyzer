defmodule DxnnAnalyzerWeb.AnalyzerBridge.PopulationOperations do
  @moduledoc """
  Handles population creation and management.
  """

  @doc """
  Creates a new population from selected agents.
  """
  def create_population(agent_ids, pop_name, output_path, opts \\ []) do
    pop_name_atom = String.to_atom(pop_name)
    output_charlist = String.to_charlist(output_path)
    erlang_opts = convert_opts_to_erlang(opts)

    :analyzer.create_population(agent_ids, pop_name_atom, output_charlist, erlang_opts)
  end

  # Private helpers

  defp convert_opts_to_erlang(opts) do
    Enum.map(opts, fn
      {:context, val} -> {:context, String.to_atom(val)}
      {key, val} -> {key, val}
    end)
  end
end
