defmodule Nimble.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:email, :string, null: false)
      add(:first_name, :string)
      add(:last_name, :string)
      add(:role, :string, default: "user")
      add(:avatar, :string)

      add(:phone, :string)

      add(:password_hash, :string, null: true)
      add(:confirmed_at, :naive_datetime)

      add(:is_admin, :boolean, default: false, null: false)

      timestamps()
    end

    create unique_index(:users, [:email])

  end
end
