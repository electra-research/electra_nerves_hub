defmodule NervesHub.Logs.LogDispatcher do
  use Task, restart: :permanent
  import Ecto.Query
  alias NervesHub.Repo
  alias NervesHub.Logs.Log
  require Logger

  @bucket_name "electra-telemetry"
  @interval Application.compile_env(:nerves_hub, :log_put_interval_ms, 60_000)
  @batch_size Application.compile_env(:nerves_hub, :log_put_batch_size, 1000)

  def start_link(_), do: Task.start_link(fn ->
    Process.sleep(@interval)
    Logger.info("[#{__MODULE__}] sending logs...")
    from(l in Log, order_by: l.logged_at, limit: @batch_size)
    |> Repo.all()
    |> put_logs_on_remote()
    |> Task.await_many()
    |> delete_local_copies()
  end)

  defp put_logs_on_remote(logs) do
    Enum.map(logs, fn l ->
      req = ExAws.S3.put_object(
        @bucket_name,
        "#{l.device_id}/#{Time.to_iso8601(Time.utc_now())}",
        l.message,
        []
      )
      Task.async(fn -> {l, ExAws.request(req)} end)
    end)
  end

  defp delete_local_copies(log_reqs) do
    ids = Enum.flat_map(log_reqs, fn
      {l, {:ok, _}} -> [l.id]
      {l, _} ->
        Logger.warning("[#{__MODULE__}] log not stored on remote, retaining: #{l.id}")
        []
    end)

    Repo.delete_all(from(l in Log, where: l.id in ^ids))
  end
end
