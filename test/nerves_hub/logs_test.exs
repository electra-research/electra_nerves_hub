defmodule NervesHub.LogsTest do
  use NervesHub.DataCase, async: false
  alias NervesHub.Logs
  alias NervesHub.Logs.Log
  alias NervesHub.Devices.Device
  alias NervesHub.Fixtures
  alias NervesHub.Repo

  setup do
    user = Fixtures.user_fixture()
    org = Fixtures.org_fixture(user)
    product = Fixtures.product_fixture(user, org)
    org_key = Fixtures.org_key_fixture(org, user)
    firmware = Fixtures.firmware_fixture(org_key, product)
    device = Fixtures.device_fixture(org, product, firmware, %{status: :provisioned})
    device2 = Fixtures.device_fixture(org, product, firmware)
    device3 = Fixtures.device_fixture(org, product, firmware)

    {:ok,
     %{
       device: device,
       device2: device2,
       device3: device3,
     }}
  end

  test "create_log/4", %{device: device} do
    device_id = device.id
    level = "info"
    message = "hi"
    logged_at = now()
    {:ok, log} = Logs.create_log(device, level, logged_at, message)
    %Log{
      id: log_id,
      device: %Device{id: ^device_id},
      logged_at: ^logged_at,
      level: ^level,
      message: ^message,
    } = log

    [%Log{
      id: ^log_id,
      device: %Device{id: ^device_id},
      logged_at: ^logged_at,
      level: ^level,
      message: ^message,
    }] = Repo.preload(device, logs: :device).logs
  end

  test "associations", %{device: device1, device2: device2} do
    log11 = random_log(device1)
    log12 = random_log(device1)
    log21 = random_log(device2)
    log22 = random_log(device2)

    [device1, device2] = Repo.preload([device1, device2], :logs)

    2 = length(device1.logs)
    2 = length(device2.logs)
    assert Enum.sort([log11.id, log12.id]) == Enum.sort(device1.logs |> Enum.map(&(&1.id)))
    assert Enum.sort([log21.id, log22.id]) == Enum.sort(device2.logs |> Enum.map(&(&1.id)))
  end

  defp now() do
    {:ok, ts} = DateTime.now("Etc/UTC")
    ts
  end

  defp random_word(n \\ 6) do
    (1..n) |> Enum.map(fn _ -> Enum.random((?a..?z)) end) |> to_string()
  end

  defp random_log(device) do
    {:ok, log} = Logs.create_log(device, random_word(), now(), random_word())
    log
  end
end
