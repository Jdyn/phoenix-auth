defmodule Nimble.User do
  @moduledoc """
  Defines a User model to track and authenticate users across the application.
  """
  use Nimble.Web, :model

  alias Nimble.Repo
  alias Nimble.User
  alias Nimble.UserToken
  alias Nimble.Util.PhoneNumber

  @derive {Inspect, except: [:password]}

  @registration_fields ~w(identifier username full_name)a
  @update_fields ~w(email phone username full_name)a
  @email_regex ~r/^[^\s]+@[^\s]+$/

  schema "users" do
    # Field used to accept an email OR phone to create an account.
    # It is not stored in the database.
    field(:identifier, :string, virtual: true)

    field(:email, :string)
    field(:phone, :string)
    field(:username, :string)
    field(:full_name, :string)
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
    |> cast(attrs, [:identifier, :username, :full_name, :password])
    |> validate_required([:identifier, :username, :full_name, :password])
    |> validate_identifier()
    |> validate_password()
    |> check_constraint(:users, name: :validate_email_or_phone)
  end

  def update_changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, @update_fields)
    |> validate_required(@update_fields)
    |> validate_identifier()
  end

  def oauth_registration_changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, @registration_fields)
    |> validate_required(@registration_fields)
    |> confirm_oauth_email(attrs.email_verified)
  end

  defp validate_identifier(changeset) do
    identifier = get_change(changeset, :identifier)

    if is_nil(identifier) do
      validate_required(changeset, [:identifier])
    else
      with {:ok, _} <- PhoneNumber.parse_phone_number(identifier) do
        validate_phone(changeset)
      else
        _ -> validate_email(changeset)
      end
    end
  end

  defp validate_email(changeset) do
    changeset
    |> put_change(:email, get_change(changeset, :identifier) || get_change(changeset, :email))
    |> validate_required([:email])
    |> update_change(:email, &String.downcase(&1))
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 80)
    |> unsafe_validate_unique(:email, Repo)
    |> unique_constraint(:email)
  end

  defp validate_phone(changeset) do
    phone = get_change(changeset, :identifier)

    with {:ok, phone_number} <- PhoneNumber.parse_phone_number(phone),
         true <- PhoneNumber.possible_phone?(phone_number),
         true <- PhoneNumber.valid_phone?(phone_number) do
      phone_number = PhoneNumber.format_phone_number(phone_number, :e164)

      changeset
      |> put_change(:phone, phone_number)
      |> validate_required([:phone])
      |> validate_length(:phone, max: 25)
      |> unsafe_validate_unique(:phone, Repo)
      |> unique_constraint(:phone)
    else
      {:error, message} -> add_error(changeset, :phone, message)
      _ -> add_error(changeset, :phone, "That's not a valid
                           phone number or it's missing your country code.")
    end
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 80)
    |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> prepare_changes(&maybe_hash_password/1)
  end

  defp maybe_hash_password(changeset) do
    if password = get_change(changeset, :password) do
      changeset
      |> put_change(:password_hash, Pbkdf2.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
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
  def confirm_changeset(user_or_changeset) do
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
    change(user_or_changeset, confirmed_at: now)
  end

  def confirm_oauth_email(changeset, true) do
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
    change(changeset, confirmed_at: now)
  end

  def confirm_oauth_email(changeset, false), do: add_error(changeset, :email_verified, "Email not verified")

  @doc """
  Verifies the password.
  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%User{password_hash: password_hash}, password)
      when is_binary(password_hash) and byte_size(password) > 0 do
    Pbkdf2.verify_pass(password, password_hash)
  end

  def valid_password?(_, _), do: Pbkdf2.no_user_verify()

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
