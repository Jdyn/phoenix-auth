defmodule Nimble.UserNotifier do
  @moduledoc false
  import Swoosh.Email

  alias Nimble.Mailer

  @delivery_name "Nimble"
  @delivery_email "no-reply@nimble.com"
  @delivery_url "http://localhost:4000"

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({@delivery_name, @delivery_email})
      |> subject(subject)
      |> html_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, token) do
    deliver(user.email, "Email Confirmation instructions", """
    Hello,
    <p>
      You can confirm your account by visiting the URL below:
    </p>

    <p>
      <a href="#{@delivery_url}/account/email/confirm/#{token}">
        #{@delivery_url}/account/email/confirm/#{token}
      </a>
    </p>

    <p>
      If you didn't create an account with us, please ignore this.
    </p>
    """)
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_password_reset_instructions(user, token) do
    deliver(user.email, "Reset password instructions", """

    ==============================

    Hi #{user.email},

    You can reset your password by visiting the URL below:

    <p>
      <a href="#{@delivery_url}/user/password/update/#{token}">
        #{@delivery_url}/user/password/update/#{token}
      </a>
    </p>

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_user_update_email_instructions(user, token) do
    deliver(user.email, "Update email instructions", """

    ==============================

    Hi #{user.email},

    You can change your email by visiting the URL below:

    <p>
      <a href="#{@delivery_url}/user/email/update/#{token}">
        #{@delivery_url}/user/email/update/#{token}
      </a>
    </p>

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end
end
