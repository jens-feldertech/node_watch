defmodule NodeWatchWeb.Dashboard do
  use Phoenix.LiveView

  alias Phoenix.PubSub

  def mount(_params, _session, socket) do
    nodes = Application.get_env(:node_watch, :nodes)

    if connected?(socket) do
      PubSub.subscribe(NodeWatch.PubSub, "sla")
    end

    sla_levels =
      case Map.has_key?(socket.assigns, :sla_levels) do
        true -> socket.assigns.sla_levels
        false -> nil
      end

    socket =
      assign(
        socket,
        nodes: nodes,
        sla_levels: sla_levels
      )

    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@4.1.3/dist/css/bootstrap.min.css" integrity="sha384-MCw98/SFnGE8fJT3GXwEOngsV7Zt27NXFoaoApmYm81iuXoPkFOJwJ8ERdknLPMO" crossorigin="anonymous">
    <body>
      <div class="d-flex align-items-center" style="height: 70vh;">
        <div class="container-fluid">
          <div class="row">
            <div class="col-sm-10 offset-sm-1">
              <div class="card">
                <div class="card-body">
                  <div class="card-body">
                  <table class="table table-striped text-left">
                    <thead>
                      <tr>
                        <th>Name</th>
                        <th>URL</th>
                        <th>Chain</th>
                        <th>Trusted</th>
                        <th>SLA</th>
                      </tr>
                    </thead>
                    <tbody>
                      <%= for node <- @nodes do %>
                        <td>
                          <%= node.name %>
                        </td>
                        <td>
                          <%= node.url %>
                        </td>
                        <td>
                          <%= node.chain %>
                        </td>
                        <td>
                          <%= node.trusted %>
                        </td>
                        <td>
                          <%= if @sla_levels do %>
                            <%= @sla_levels[node.url] %>%
                          <% else %>
                            N/A
                          <% end %>
                        </td>
                      </tr>
                      <% end %>
                    </tbody>
                  </table>
                </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </body>
    """
  end

  def handle_info(message, socket) do
    {:noreply, assign(socket, sla_levels: message)}
  end
end
