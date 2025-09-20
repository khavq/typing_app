defmodule TypingApp.Repo.Migrations.AddBackgroundMusicToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :background_music_enabled, :boolean, default: false, null: false
    end
  end
end
