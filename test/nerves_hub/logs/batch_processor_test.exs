defmodule NervesHub.Logs.BatchProcessorTest do
  use NervesHub.DataCase, async: true

  alias NervesHub.Logs
  alias NervesHub.Logs.BatchProcessor
  alias NervesHub.Fixtures

  setup do
    user = Fixtures.user_fixture()
    org = Fixtures.org_fixture(user)
    product = Fixtures.product_fixture(user, org)
    org_key = Fixtures.org_key_fixture(org, user)
    firmware = Fixtures.firmware_fixture(org_key, product)
    device = Fixtures.device_fixture(org, product, firmware, %{status: :provisioned})

    {:ok, %{ device: device }}
  end

  test "object_name_and_contents/2", %{device: device} do
    did = device.identifier
    logs = Enum.map(1..10, fn n -> random_log(device, n) end)
    expected_name = "#{did}/#{List.first(logs).logged_at}"
    expected_contents = logs
                        |> Enum.map(fn l -> "#{l.logged_at} [#{l.level}] #{l.message}" end)
                        |> Enum.join("\n")
    {^expected_name, ^expected_contents} = BatchProcessor.object_name_and_contents(did, logs)
  end


  defp random_word(n \\ 6) do
    (1..n) |> Enum.map(fn _ -> Enum.random((?a..?z)) end) |> to_string()
  end

  defp random_log(device, offset) do
    {:ok, now} = DateTime.now("Etc/UTC")
    {:ok, log} = Logs.create_log(device, random_word(), DateTime.add(now, offset), random_word())
    log
  end
end
