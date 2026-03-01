defmodule DxnnAnalyzerWeb.TopologyViewerLive do
  use DxnnAnalyzerWeb, :live_view
  alias DxnnAnalyzerWeb.AnalyzerBridge

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok, assign(socket, :agent_id, URI.decode(id))}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    context = params["context"]

    socket =
      if context do
        agent_id = parse_agent_id(socket.assigns.agent_id)

        case AnalyzerBridge.get_topology(agent_id, context) do
          topology when is_map(topology) ->
            socket
            |> assign(:context, context)
            |> assign(:topology, topology)
            |> assign(:error, nil)

          _ ->
            socket
            |> assign(:context, context)
            |> assign(:topology, nil)
            |> assign(:error, "Failed to load topology")
        end
      else
        assign(socket, :error, "No context specified")
      end

    {:noreply, socket}
  end

  defp parse_agent_id(id_str) do
    {agent_id, _} = Code.eval_string(id_str)
    agent_id
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div class="mb-6">
          <.link navigate={~p"/agents/#{URI.encode(@agent_id)}?context=#{@context}"} class="text-blue-600 hover:text-blue-800 text-sm mb-2 inline-block">
            ← Back to Agent Inspector
          </.link>
          <h1 class="text-3xl font-bold text-gray-900">Neural Network Topology</h1>
          <p class="text-gray-600 mt-1">Agent: <%= @agent_id %></p>
        </div>

        <%= if @error do %>
          <div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded mb-6">
            <%= @error %>
          </div>
        <% end %>

        <%= if @topology do %>
          <div class="space-y-6">
            <!-- Topology Stats -->
            <div class="bg-white shadow rounded-lg p-6">
              <h2 class="text-xl font-semibold mb-4">Network Statistics</h2>
              <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div class="text-center p-4 bg-blue-50 rounded">
                  <div class="text-3xl font-bold text-blue-600">
                    <%= length(Map.get(@topology, :sensors, [])) %>
                  </div>
                  <div class="text-sm text-gray-600 mt-1">Sensors</div>
                </div>
                <div class="text-center p-4 bg-green-50 rounded">
                  <div class="text-3xl font-bold text-green-600">
                    <%= length(Map.get(@topology, :neurons, [])) %>
                  </div>
                  <div class="text-sm text-gray-600 mt-1">Neurons</div>
                </div>
                <div class="text-center p-4 bg-purple-50 rounded">
                  <div class="text-3xl font-bold text-purple-600">
                    <%= length(Map.get(@topology, :actuators, [])) %>
                  </div>
                  <div class="text-sm text-gray-600 mt-1">Actuators</div>
                </div>
                <div class="text-center p-4 bg-orange-50 rounded">
                  <div class="text-3xl font-bold text-orange-600">
                    <%= Map.get(@topology, :layer_count, 0) %>
                  </div>
                  <div class="text-sm text-gray-600 mt-1">Layers</div>
                </div>
              </div>
            </div>

            <!-- Sensors -->
            <%= if Map.has_key?(@topology, :sensors) && length(@topology.sensors) > 0 do %>
              <div class="bg-white shadow rounded-lg p-6">
                <h2 class="text-xl font-semibold mb-4">Sensors</h2>
                <div class="space-y-2">
                  <%= for sensor <- @topology.sensors do %>
                    <div class="border border-gray-200 rounded p-3 text-sm">
                      <span class="font-mono text-blue-600"><%= inspect(sensor) %></span>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>

            <!-- Neurons by Layer -->
            <%= if Map.has_key?(@topology, :neurons) && length(@topology.neurons) > 0 do %>
              <div class="bg-white shadow rounded-lg p-6">
                <h2 class="text-xl font-semibold mb-4">Neurons</h2>
                <div class="text-sm text-gray-600 mb-4">
                  Total: <%= length(@topology.neurons) %> neurons
                </div>
                <div class="space-y-2 max-h-96 overflow-y-auto">
                  <%= for neuron <- Enum.take(@topology.neurons, 50) do %>
                    <div class="border border-gray-200 rounded p-2 text-xs font-mono">
                      <%= inspect(neuron) %>
                    </div>
                  <% end %>
                  <%= if length(@topology.neurons) > 50 do %>
                    <div class="text-center text-gray-500 text-sm py-2">
                      ... and <%= length(@topology.neurons) - 50 %> more neurons
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>

            <!-- Actuators -->
            <%= if Map.has_key?(@topology, :actuators) && length(@topology.actuators) > 0 do %>
              <div class="bg-white shadow rounded-lg p-6">
                <h2 class="text-xl font-semibold mb-4">Actuators</h2>
                <div class="space-y-2">
                  <%= for actuator <- @topology.actuators do %>
                    <div class="border border-gray-200 rounded p-3 text-sm">
                      <span class="font-mono text-purple-600"><%= inspect(actuator) %></span>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>

            <!-- Visualization Placeholder -->
            <div class="bg-white shadow rounded-lg p-6">
              <h2 class="text-xl font-semibold mb-4">Network Visualization</h2>
              <div class="bg-gray-100 rounded-lg p-8 text-center">
                <p class="text-gray-600">
                  Interactive network visualization will be rendered here using D3.js or Cytoscape.js
                </p>
                <p class="text-sm text-gray-500 mt-2">
                  This requires additional JavaScript implementation
                </p>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
