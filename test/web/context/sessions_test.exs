defmodule Nimble.SessionsTest do
  use Nimble.DataCase

  import Nimble.AccountsFixtures

  alias Nimble.Accounts.Sessions
  alias Nimble.UserToken

  describe "create_session_token/1" do
    setup do
      %{user: user_fixture()}
    end

    test "generates a token", %{user: user} do
      token = Sessions.create_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.context == "session"

      # Creating the same token for another user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%UserToken{
          token: user_token.token,
          user_id: user_fixture().id,
          context: "session",
          tracking_id: "123"
        })
      end
    end
  end
end
