defmodule TypingApp.Repo.Migrations.AddTypingSoundEnabledToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :typing_sound_enabled, :boolean, default: true, null: false
    end
  end
end
