defmodule NodeWatch.SLA.Worker do
  use GenServer

  alias NodeWatch.SLA.Calculator

  require Logger

  # 24 Hours
  @interval 86_400_000
  @interval 86_400_000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    schedule()
    {:ok, opts}
  end

  def handle_info(:calculate_sla, state) do
    schedule()
    {:noreply, state}
  end

  defp schedule() do
    Process.send_after(self(), :calculate_sla, @interval)
  end

  defp calculate_sla() do
    Calculator.daily_sla()
  end
end
