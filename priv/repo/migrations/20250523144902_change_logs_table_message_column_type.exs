defmodule NervesHub.Repo.Migrations.ChangeLogsTableMessageColumnType do
  use Ecto.Migration

  def up do
    drop table(:logs)
    create table(:logs) do
      add :device_id, references(:devices)
      add :logged_at, :utc_datetime_usec, null: false
      add :level, :string, null: false
      add :message, :text, null: false
      timestamps()
    end
  end

  def down do
    create table(:logs) do
      add :device_id, references(:devices)
      add :logged_at, :utc_datetime_usec, null: false
      add :level, :string, null: false
      add :message, :string, null: false
      timestamps()
    end
  end
end
