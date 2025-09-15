defmodule TypingApp.Repo.Migrations.CreateUserProgress do
  use Ecto.Migration

  def change do
    create table(:user_progress) do
      add :current_level, :integer, default: 1
      add :total_score, :integer, default: 0
      add :best_wpm, :float, default: 0.0
      add :games_played, :integer, default: 0
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:user_progress, [:user_id])
  end
end
