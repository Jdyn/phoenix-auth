defmodule Nimble.Repo.Migrations.CreateTokens do
  use Ecto.Migration

  def change do
    create table(:tokens) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:token, :binary, null: false)
      add(:tracker_id, :string, null: false)
      add(:context, :string, null: false)
      add(:sent_to, :string)

      timestamps(updated_at: false)
    end

    create(index(:tokens, [:user_id]))
    create(unique_index(:tokens, [:context, :token]))
  end
end
