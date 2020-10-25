defmodule Nimble.Auth.FetchUser do
  import Plug.Conn
  use Phoenix.Controller

  alias Nimble.Service.Users

  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "auth_token"
  @remember_me_options [sign: true, max_age: @max_age]

  def init(opts), do: opts

  @doc """
  Authenticates the user by looking into the session
  and remember me token.
  """
  def call(conn, _opts) do
    {token, conn} = ensure_user_token(conn)
    user = token && Users.find_by_session_token(token)

    assign(conn, :current_user, user)
  end

  defp ensure_user_token(conn) do
    if user_token = get_session(conn, :user_token) do
      if conn.cookies[@remember_me_cookie] do
        {user_token, conn}
      else
        {user_token, put_resp_cookie(conn, @remember_me_cookie, user_token, @remember_me_options)}
      end
    else
      conn = fetch_cookies(conn)
      auth_token = conn.cookies[@remember_me_cookie]

      if (auth_token) do
        {Base.url_decode64!(auth_token, padding: false), conn}
      else
        {nil, conn}
      end
    end
  end
end
