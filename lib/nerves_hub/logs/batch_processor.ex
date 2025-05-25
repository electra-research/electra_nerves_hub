defmodule NervesHub.Logs.BatchProcessor do
  use Task, restart: :permanent
  import Ecto.Query
  alias NervesHub.Repo
  alias NervesHub.Logs.Log
  require Logger
  @interval 60_000 # every minute
  @batch_size 1000 # send a thousand logs
  @bucket "electra-telemetry"
  def start_link(_), do: Task.start_link(fn ->
    Process.sleep(@interval)
    Logger.info("[#{__MODULE__}] sending logs...")
    from(l in Log, order_by: l.logged_at, limit: @batch_size, preload: [:device])
    |> Repo.all()
    |> store_logs()
    |> Task.await_many()
    |> select_stored_logs()
    |> delete_stored_logs()
  end)

  defp select_stored_logs(log_reqs) do
    Enum.flat_map(log_reqs, fn
      {l, {:ok, _}} -> [l.id]
      {l, _} ->
        Logger.warning("[#{__MODULE__}] log not stored in s3, retaining: #{l.id}")
        []
    end)
  end

  defp store_logs(logs) do
    Enum.map(logs, fn l ->
      req = ExAws.S3.put_object(
        @bucket,
        "#{l.device.identifier}/#{l.logged_at}",
        "[#{l.level}] #{l.message}",
        []
      )
      Task.async(fn -> {l, ExAws.request(req)} end)
    end)
  end

  defp delete_stored_logs(ids) do
    from(l in Log, where: l.id in ^ids)
    |> Repo.delete_all()
  end
end
