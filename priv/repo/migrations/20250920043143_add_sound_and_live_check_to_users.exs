defmodule TypingApp.Repo.Migrations.AddSoundAndLiveCheckToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :sound_enabled, :boolean, default: true, null: false
      add :live_check, :boolean, default: false, null: false
    end
  end
end
