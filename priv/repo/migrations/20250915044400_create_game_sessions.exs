defmodule TypingApp.Repo.Migrations.CreateGameSessions do
  use Ecto.Migration

  def change do
    create table(:game_sessions) do
      add :level, :integer, null: false
      add :score, :integer, null: false, default: 0
      add :wpm, :float, default: 0.0
      add :accuracy, :float, default: 100.0
      add :time_taken, :integer
      add :completed_at, :naive_datetime
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:game_sessions, [:user_id])
    create index(:game_sessions, [:level])
    create index(:game_sessions, [:completed_at])
    create index(:game_sessions, [:user_id, :level])
  end
end
