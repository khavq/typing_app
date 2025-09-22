defmodule TypingApp.Repo.Migrations.AddSelectedSourceToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :selected_source, :string, default: "zenquotes"
    end
  end
end
