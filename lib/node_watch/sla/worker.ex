defmodule NodeWatch.SLA.Worker do
  @moduledoc """
    This module is responsible for periodically calculating SLA for the nodes.
    The first job is scheduled based on the current time.
    Every job after that is scheduled with a fixed interval set to 24 hours
  """
  use GenServer

  alias Phoenix.PubSub

  alias NodeWatch.SLA.Calculator

  require Logger

  # 24 Hours in milliseconds
  @interval 86_400_000

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  # Initialize the GenServer
  # Schedule the first job with interval based on current time
  def init(_) do
    initial_interval = calculate_interval()

    schedule_next_job(initial_interval)
    {:ok, nil}
  end

  def handle_info(:calculate_sla, _) do
    calculate_sla()
    schedule_next_job()
    {:noreply, nil}
  end

  defp schedule_next_job(initial_interval) do
    Process.send_after(self(), :calculate_sla, initial_interval)
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

  def calculate_interval() do
    # Get current time
    {_date, {current_hours, current_minutes, _s}} = :calendar.local_time()

    # Define desired time
    {desired_hours, desired_minutes, _s} = {23, 55, 0}

    # Calculate target time
    {target_hours, target_minutes, _s} = {desired_hours-current_hours, desired_minutes-current_minutes, 0}

    # Calculate target interval in milliseconds
    target_minutes * 60_000 + target_hours * 60_000 * 60
  end
end
