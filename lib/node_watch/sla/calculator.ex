defmodule NodeWatch.SLA.Calculator do
  @moduledoc """
  Calculates the down time for each node based on availability logs
  and assigns sla level based on the given criteria.

  99% = max. downtime of 15 minutes / day
  96% = max. downtime of 1 hour / day
  88% = max. downtime of 3 hours / day
  75% = max. downtime of 6 hours / day
  50% = max. downtime of 12 hours / day
  """

  @log_file "logs/availability.log"
  @log_separator "; "

  def daily_sla() do
    @log_file
    |> create_file_stream()
    |> get_availability_lines_by_date()
    |> group_by_node()
    |> calculate_down_times()
    |> assign_sla_levels()
    |> convert_to_map()
  end

  defp create_file_stream(file_path) do
    file_path
    |> File.stream!()
    |> Enum.reverse()
  end

  defp get_availability_lines_by_date(file_stream) do
    file_stream
    |> Enum.reduce_while([], fn line, acc ->
      line_date = get_line_date(line)

      if String.contains?(line, "availability_check") do
        if line_date_within_today?(line_date) do
          {:cont, [line | acc]}
        else
          {:halt, acc}
        end
      else
        {:cont, acc}
      end
    end)
    |> Enum.reverse()
  end

  defp group_by_node(log_lines) do
    log_lines
    |> Enum.map(&String.split(&1, @log_separator))
    |> Enum.group_by(fn [_, _, _, _, _, node, _] ->
      node
    end)
  end

  defp calculate_down_times(grouped_logs) do
    Enum.map(grouped_logs, fn {node, logs} ->
      %{down_time: node_down_time} = calculate_node_down_time(logs)
      {node, node_down_time}
    end)
  end

  defp assign_sla_levels(node_down_times) do
    Enum.map(node_down_times, fn {chain, down_time} ->
      {chain, sla_level(down_time)}
    end)
  end

  defp calculate_node_down_time(node_logs) do
    acc = %{last_line: %{level: "[info]", time: nil}, down_time: 0}

    Enum.reduce(node_logs, acc, fn current_line, acc ->
      [_, _, line_level, _, _, _, _] = current_line

      case {acc.last_line.level, line_level} do
        {"[error]", "[info]"} ->
          acc
          |> update_down_time(current_line)
          |> update_last_line(current_line)

        {"[info]", "[error]"} ->
          update_last_line(acc, current_line)

        _ ->
          acc
      end
    end)
  end

  defp update_last_line(acc, current_line) do
    [_, time, level, _, _, _, _] = current_line

    Map.put(acc, :last_line, %{level: level, time: time})
  end

  defp line_date_within_today?(line_date) do
    {:ok, log_date} = Date.from_iso8601(line_date)

    log_date == Date.utc_today()
  end

  defp sla_level(down_time) do
    cond do
      down_time <= 900_000 -> 99
      down_time <= 3_600_000 -> 96
      down_time <= 10_800_000 -> 88
      down_time <= 21_600_000 -> 75
      down_time <= 43_200_000 -> 50
      true -> 0
    end
  end

  defp get_line_date(line) do
    [line_date | _t] = String.split(line, @log_separator)

    line_date
  end

  defp update_down_time(acc, current_line) do
    [_, time, _, _, _, _, _] = current_line

    {:ok, last_line_time} = Time.from_iso8601(acc.last_line.time)
    {:ok, current_line_time} = Time.from_iso8601(time)
    diff = Time.diff(current_line_time, last_line_time, :millisecond)
    down_time = acc.down_time + diff

    Map.put(acc, :down_time, down_time)
  end

  defp convert_to_map(slas), do: Enum.into(slas, %{})
end
