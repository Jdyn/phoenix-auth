defmodule Nimble.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Nimble.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "Password123!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      identifier: unique_user_email(),
      password: valid_user_password(),
      username: "johndoe123",
      full_name: "John Doe",
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Nimble.Accounts.register()

    user
  end

  def extract_user_token_from_email(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
