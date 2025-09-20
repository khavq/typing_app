defmodule TypingApp.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS citext"
    
    # First alter the users table to make name nullable and add required columns
    alter table(:users) do
      # Make name column nullable
      modify :name, :string, null: true
      
      # Add columns if they don't exist
      add_if_not_exists :email, :citext, null: true
      add_if_not_exists :hashed_password, :string
      add_if_not_exists :confirmed_at, :utc_datetime
    end

    # Create index only if it doesn't exist
    create_if_not_exists unique_index(:users, [:email])

    create table(:users_tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      add :authenticated_at, :utc_datetime

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])
  end

  def down do
    # Drop the users_tokens table and indexes
    drop index(:users_tokens, [:context, :token])
    drop index(:users_tokens, [:user_id])
    drop table(:users_tokens)

    # Drop the email index
    drop_if_exists index(:users, [:email])
    
    # Remove the columns we added
    alter table(:users) do
      remove_if_exists :email, :citext
      remove_if_exists :hashed_password, :string
      remove_if_exists :confirmed_at, :utc_datetime
    end
    
    # Note: We don't drop the citext extension as other tables might be using it
  end
end
