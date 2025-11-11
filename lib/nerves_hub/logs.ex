defmodule NervesHub.Logs do
  alias NervesHub.Logs.Log

  def create_log(device, message) do
    NervesHub.Repo.insert(%Log{
      device: device,
      level: "",
      logged_at: DateTime.utc_now(),
      message: message,
    })
  end
end
