defmodule NervesHub.Logs.Log do
  use Ecto.Schema
  alias NervesHub.Devices.Device

  @type t :: %__MODULE__{}

  schema "logs" do
    belongs_to(:device, Device)

    field(:logged_at, :utc_datetime_usec)
    field(:level, :string)
    field(:message, :string)

    timestamps()
  end
end
