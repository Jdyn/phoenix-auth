defmodule Nimble.UsersTest do
  use Nimble.DataCase

  import Nimble.AccountsFixtures

  alias Nimble.Accounts
  alias Nimble.User
  alias Nimble.Users
  alias Nimble.UserToken

  describe "get_by_email/1" do
    test "does not return the user if the email does not exist" do
      refute Users.get_by_email("unknown@example.com")
    end

    test "returns the user if the email exists" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Users.get_by_email(user.email)
    end
  end

  describe "get_by_email_and_password/2" do
    test "does not return the user if the email does not exist" do
      refute Users.get_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the user if the password is not valid" do
      user = user_fixture()
      refute Users.get_by_email_and_password(user.email, "invalid")
    end

    test "returns the user if the email and password are valid" do
      %{id: id} = user = user_fixture()

      assert %User{id: ^id} =
               Users.get_by_email_and_password(user.email, valid_user_password())
    end
  end

  describe "deliver_password_reset_instructions/2" do
    setup do
      %{user: user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      {:ok, token} = Users.deliver_password_reset_instructions(user)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "reset_password"
    end
  end

  describe "update_email/2" do
    setup do
      user = user_fixture()
      email = unique_user_email()

      {:ok, token} =
        Users.deliver_email_update_instructions(%{user | email: email}, user.email)

      %{user: user, token: token, email: email, error: {:not_found, "Invalid link. Please generate a new one."}}
    end

    test "updates the email with a valid token", %{user: user, token: token, email: email} do
      assert Users.update_email(user, token) == :ok
      changed_user = Repo.get!(User, user.id)
      assert changed_user.email != user.email
      assert changed_user.email == email
      assert changed_user.confirmed_at
      assert changed_user.confirmed_at != user.confirmed_at
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email with invalid token", %{user: user, error: error} do
      assert Users.update_email(user, "oops") == error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if user email changed", %{user: user, token: token, error: error} do
      assert Users.update_email(%{user | email: "current@example.com"}, token) == error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if token expired", %{user: user, token: token, error: error} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Users.update_email(user, token) == error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "confirm_user_email/1" do
    setup do
      user = user_fixture()

      {:ok, token} = Users.deliver_email_confirmation_instructions(user)

      %{
        user: user,
        token: token,
        error: {:not_found, "Your link is either invalid, or your email has already been confirmed."}
      }
    end

    test "confirms the email with a valid token", %{user: user, token: token} do
      assert {:ok, confirmed_user} = Users.confirm_email(token)
      assert confirmed_user.confirmed_at
      assert confirmed_user.confirmed_at != user.confirmed_at
      assert Repo.get!(User, user.id).confirmed_at
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not confirm with invalid token", %{user: user, error: error} do
      assert Users.confirm_email("oops") == error
      refute Repo.get!(User, user.id).confirmed_at
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not confirm email if token expired", %{user: user, token: token, error: error} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Users.confirm_email(token) == error
      refute Repo.get!(User, user.id).confirmed_at
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "update_password/3" do
    setup do
      %{user: user_fixture()}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Users.update_password(user, valid_user_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: [
                 "at least one digit or punctuation character",
                 "at least one upper case character",
                 "should be at least 12 character(s)"
               ],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Users.update_password(user, valid_user_password(), %{password: too_long})

      assert "should be at most 80 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{user: user} do
      {:error, changeset} =
        Users.update_password(user, "invalid", %{password: valid_user_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{user: user} do
      {:ok, user} =
        Users.update_password(user, valid_user_password(), %{
          password: "New valid password 123"
        })

      assert is_nil(user.password)
      assert Users.get_by_email_and_password(user.email, "New valid password 123")
    end

    test "deletes all tokens for the given user", %{user: user} do
      _ = Accounts.create_session_token(user)

      {:ok, _} =
        Users.update_password(user, valid_user_password(), %{
          password: "New valid password 123"
        })

      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "reset_user_password/2" do
    setup do
      %{user: user_fixture()}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Users.reset_password(user, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: [
                 "at least one digit or punctuation character",
                 "at least one upper case character",
                 "should be at least 12 character(s)"
               ],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Users.reset_password(user, %{password: too_long})
      assert "should be at most 80 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{user: user} do
      {:ok, updated_user} = Users.reset_password(user, %{password: "New valid password 123"})
      assert is_nil(updated_user.password)
      assert Users.get_by_email_and_password(user.email, "New valid password 123")
    end

    test "deletes all tokens for the given user", %{user: user} do
      _ = Accounts.create_session_token(user)
      {:ok, _} = Users.reset_password(user, %{password: "New valid password 123"})
      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "inspect/2 for the User module" do
    test "does not include password" do
      refute inspect(%User{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
