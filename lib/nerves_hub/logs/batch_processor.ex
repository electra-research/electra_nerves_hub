defmodule NervesHub.Logs.BatchProcessor do
  use Task, restart: :permanent
  import Ecto.Query
  alias NervesHub.Repo
  alias NervesHub.Logs.Log
  require Logger
  @interval_ms 60_000 # every minute
  @batch_size 1000 # send up to a thousand logs
  @bucket "electra-telemetry"
  def start_link(_), do: Task.start_link(fn ->
    Process.sleep(@interval_ms)
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
      {logs, {:ok, _}} -> Enum.map(logs, fn l -> l.id end)
      {[l|_]=logs, error} ->
        Logger.error("[#{__MODULE__}] #{Enum.count(logs)} logs for #{l.device.identifier} not stored in s3, retaining: #{inspect(error)}")
        []
    end)
  end

  def object_name_and_contents(did, [l0 | _ ] = logs) do
    name = "#{did}/#{l0.logged_at}"
    contents = Enum.join(Enum.map(logs, &logfmt/1), "\n")
    {name, contents}
  end


  defp logfmt(l) do
    "#{l.logged_at} [#{l.level}] #{l.message}"
  end

  defp store_logs(logs) do
    logs
    |> Enum.group_by(fn l -> l.device.identifier end)
    |> Enum.map(fn {did, logs} ->
      {name, contents} = object_name_and_contents(did, logs)
      req = ExAws.S3.put_object(@bucket, name, contents, [])
      Task.async(fn -> {logs, ExAws.request(req)} end)
    end)
  end

  defp delete_stored_logs(ids) do
    from(l in Log, where: l.id in ^ids)
    |> Repo.delete_all()
  end
end
