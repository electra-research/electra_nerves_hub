defmodule NervesHub.Repo.Migrations.AddLogsTable do
  use Ecto.Migration

  def up do
    create table(:logs) do
      add :device_id, references(:devices)
      add :logged_at, :utc_datetime_usec, null: false
      add :level, :string, null: false
      add :message, :string, null: false
      timestamps()
    end
  end

  def down do
    drop table(:logs)
  end
end
