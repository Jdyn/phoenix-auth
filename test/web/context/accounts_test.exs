defmodule Nimble.AccountsTest do
  use Nimble.DataCase

  import Nimble.AccountsFixtures

  alias Nimble.Accounts
  alias Nimble.Sessions
  alias Nimble.User
  alias Nimble.UserToken

  describe "reigster/1" do
    test "requires required fields to be set" do
      {:error, changeset} = Accounts.register(%{})

      assert %{
               password: ["can't be blank"],
               identifier: ["can't be blank"],
               username: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      attrs = %{identifier: "not valid", username: "johndoe123", password: "not valid"}

      {:error, changeset} =
        Accounts.register(attrs)

      assert errors_on(changeset).password != nil
      assert errors_on(changeset).password != nil
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("t", 100) <> "@example.com"
      {:error, changeset} = Accounts.register(%{identifier: too_long, password: too_long})
      assert "should be at most 80 character(s)" in errors_on(changeset).email
      assert "should be at most 80 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = user_fixture()
      {:error, changeset} = Accounts.register(%{identifier: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Accounts.register(%{identifier: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers Accounts with a hashed password" do
      email = unique_user_email()
      {:ok, user} = Accounts.register(valid_user_attributes(identifier: email))
      assert user.email == email
      assert is_binary(user.password_hash)
      assert is_nil(user.confirmed_at)
      assert is_nil(user.password)
    end
  end

  describe "deliver_email_update_instructions/3" do
    setup do
      %{user: user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      {:ok, token} = Accounts.deliver_email_update_instructions(user, "current@example.com")

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "change:current@example.com"
    end
  end

  describe "find_by_session_token/1" do
    setup do
      user = user_fixture()
      token = Sessions.create_session_token(user)
      %{user: user, token: token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert session_user = Sessions.user_from_session(token)
      assert session_user.id == user.id
    end

    test "does not return user for invalid token" do
      refute Sessions.user_from_session("oops")
    end

    test "does not return user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Sessions.user_from_session(token)
    end
  end

  describe "delete_session_token/1" do
    test "deletes the token" do
      user = user_fixture()
      token = Sessions.create_session_token(user)
      assert Sessions.delete_session_token(token) == :ok
      refute Sessions.user_from_session(token)
    end
  end

  describe "deliver_user_confirmation_instructions/2" do
    setup do
      %{user: user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      {:ok, token} =
        Accounts.deliver_email_confirmation_instructions(user)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "confirm"
    end
  end

  describe "get_user_by_reset_password_token/1" do
    setup do
      user = user_fixture()

      {:ok, token} = Accounts.deliver_password_reset_instructions(user)

      %{user: user, token: token, error: {:error, "Reset password link is invalid or it has expired."}}
    end

    test "returns the user with valid token", %{user: %{id: id}, token: token} do
      assert {:ok, %User{id: ^id}} = Accounts.get_user_by_reset_password_token(token)
      assert Repo.get_by(UserToken, user_id: id)
    end

    test "does not return the user with invalid token", %{user: user, error: error} do
      assert Accounts.get_user_by_reset_password_token("oops") == error
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not return the user if token expired", %{user: user, token: token, error: error} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.get_user_by_reset_password_token(token) == error
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end
end
