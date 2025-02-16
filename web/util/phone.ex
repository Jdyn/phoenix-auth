defmodule Nimble.Util.Phone do
  @moduledoc """
  Functions for implementing phone number validations and formatting
  using [ex_phone_number](https://hex.pm/packages/ex_phone_number).
  """

  alias ExPhoneNumber.Model.PhoneNumber

  @type phone_types ::
          :fixed_line
          | :mobile
          | :fixed_line_or_mobile
          | :toll_free
          | :premium_rate
          | :shared_cost
          | :voip
          | :personal_number
          | :pager
          | :uan
          | :voicemail
          | :unknown

  @doc """
  Parses a given phone number string.

    ## Example
      iex > {:ok, phone_number} = ExPhoneNumber.parse("044 668 18 00", "CH")
      {:ok,
        %ExPhoneNumber.Model.PhoneNumber{
          country_code: 41,
          country_code_source: nil,
          extension: nil,
          italian_leading_zero: nil,
          national_number: 446681800,
          number_of_leading_zeros: nil,
          preferred_domestic_carrier_code: nil,
          raw_input: nil
      }}
  """

  @spec parse(String.t(), String.t()) :: {:ok, %PhoneNumber{}} | {:error, String.t()}
  def parse(phone_number, opts \\ "US") do
    ExPhoneNumber.parse(phone_number, opts)
  end

  @doc """
  Checks whether a given phone number is possible.
  Returns true or false.
  """
  @spec possible?(%PhoneNumber{}) :: boolean()
  def possible?(phone_number) do
    ExPhoneNumber.is_possible_number?(phone_number)
  end

  @doc """
  Checks whether a given phone number is valid.
  Returns true or false.
  """
  @spec valid?(%PhoneNumber{}) :: boolean()
  def valid?(phone_number) do
    ExPhoneNumber.is_valid_number?(phone_number)
  end

  @doc """
  Checks the type of phone number, e.g. `:fixed` or
  `:fixed_line_or_mobile`.
  """
  @spec type(%PhoneNumber{}) :: phone_types()
  def type(phone_number) do
    ExPhoneNumber.get_number_type(phone_number)
  end

  @doc """
  Formats a phone number.
  opts: :national, :international, :e164, :rfc3966
  """
  @spec format(%PhoneNumber{}, atom()) :: String.t()
  def format(phone_number, opts) do
    ExPhoneNumber.format(phone_number, opts)
  end
end
