defmodule Nimble.User do
  @moduledoc """
  Defines a User model to track and authenticate users across the application.
  """

  use Nimble.Web, :model
  import Pbkdf2, only: [add_hash: 1, verify_pass: 2, no_user_verify: 0]

  alias Nimble.{User, UserToken}

  schema "users" do
    field(:email, :string)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:role, :string, default: "user")
    field(:avatar, :string)

    field(:password_hash, :string)
    field(:password, :string, virtual: true)

    field(:confirmed_at, :naive_datetime)

    field(:is_admin, :boolean, default: false)

    has_many(:tokens, UserToken)

    timestamps()
  end

  @doc """
  A user changeset for registration.
  It is important to validate the length of both e-mail and password.
  Otherwise databases may truncate the e-mail without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.
  """
  def registration_changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:email, :password, :first_name, :last_name])
    |> validate_required([:first_name, :last_name])
    |> validate_email()
    |> validate_password()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> update_change(:email, &String.downcase(&1))
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
    |> validate_length(:email, max: 80)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 10, max: 80)
    |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> prepare_changes(&hash_password/1)
  end

  defp hash_password(changeset) do
    password = get_change(changeset, :password)

    changeset
    |> change(add_hash(password))
    |> delete_change(:password)
  end

  @doc """
  A user changeset for changing the e-mail.
  It requires the e-mail to change otherwise an error is added.
  """
  def email_changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_email()
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.
  """
  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password()
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.
  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%User{password_hash: password_hash}, password)
      when is_binary(password_hash) and byte_size(password) > 0 do
    verify_pass(password, password_hash)
  end

  def valid_password?(_, _) do
    no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end
end
