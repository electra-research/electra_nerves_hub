defmodule NervesHub.Logs do
  require Logger
  alias NervesHub.Logs.Log
  alias NervesHub.Repo
  def create_log(device, level, timestamp, message) do
    %Log{
      device: device,
      level: level,
      logged_at: timestamp,
      message: message,
    }
    |> Repo.insert()
  end
end
