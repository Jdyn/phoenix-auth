defmodule Nimble.Service.Accounts do
  import Pbkdf2, only: [check_pass: 2]

  alias Nimble.Repo
  alias Nimble.{User, Token}
  alias Nimble.Service.{Users}

  def authenticate(email, password) when is_binary(email) and is_binary(password) do
    error = {:error, "Email or Password is incorrect."}

    case Users.find_by(email: email) do
      nil ->
        error

      user ->
        case check_pass(user, password) do
          {:ok, user} ->
            {:ok, user}

          {:error, _} ->
            error
        end
    end
  end

  ## User registration

  @doc """
  Registers a user.

  ## Examples
      iex> register_user(%{field: value})
      {:ok, %User{}}
      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.
  ## Examples
      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}
  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user e-mail.
  ## Examples
      iex> change_email(user)
      %Ecto.Changeset{data: %User{}}
  """
  def change_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs)
  end

  @doc """
  Emulates that the e-mail will change without actually changing
  it in the database.
  ## Examples
      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}
      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}
  """
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user e-mail in token.
  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- Token.verify_change_email_token_query(token, context),
         %Token{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset = user |> User.email_changeset(%{email: email}) |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, Token.user_and_contexts_query(user, [context]))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.
  ## Examples
      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}
  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs)
  end

  @doc """
  Updates the user password.
  ## Examples
      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}
      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}
  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, Token.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Confirmation

  @doc """
  Confirms a user by the given token.
  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- Token.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, Token.user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc """
  Gets the user by reset password token.
  ## Examples
      iex> get_user_by_reset_password_token("validtoken")
      %User{}
      iex> get_user_by_reset_password_token("invalidtoken")
      nil
  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- Token.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.
  ## Examples
      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}
      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}
  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, Token.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end
end
