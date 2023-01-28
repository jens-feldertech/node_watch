defmodule NodeWatch.SLA.Worker do
  use GenServer

  alias Phoenix.PubSub

  alias NodeWatch.SLA.Calculator

  require Logger

  # 24 Hours
  @interval 86_400_000

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(_) do
    schedule_next_job()
    {:ok, nil}
  end

  def handle_info(:calculate_sla, _) do
    calculate_sla()
    schedule_next_job()
    {:noreply, nil}
  end

  defp schedule_next_job() do
    Process.send_after(self(), :calculate_sla, @interval)
  end

  defp calculate_sla() do
    sla_levels = Calculator.daily_sla()

    PubSub.broadcast(NodeWatch.PubSub, "sla", sla_levels)

    log_result(sla_levels)
  end

  defp log_result(result) do
    Enum.each(result, fn {chain, sla} ->
      Logger.info("sla_calculator; #{chain}; #{sla}")
    end)
  end
end
