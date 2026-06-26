defmodule Burrito.Util.Args do
  @moduledoc """
  Helpers to fetch CLI arguments passed down from the Zig wrapper binary.

  The Zig wrapper launches the BEAM with `-extra <user-args>`, so the
  arguments reach Elixir through `:init.get_plain_arguments/0`. This
  module is a thin convenience wrapper around that.

  Outside a Burrito-built context, `:init.get_plain_arguments/0` returns
  OTP runtime arguments (or `[]`). Use `argv/0` when you need true CLI
  arguments regardless of the runtime.
  """

  @spec get_arguments() :: [String.t()]
  def get_arguments do
    Enum.map(:init.get_plain_arguments(), &to_string/1)
  end

  @spec argv() :: [String.t()]
  def argv do
    if Burrito.Util.running_standalone?() do
      get_arguments()
    else
      System.argv()
    end
  end

  @spec get_bin_path() :: binary() | :not_in_burrito
  def get_bin_path do
    env_value = System.get_env("__BURRITO_BIN_PATH")

    if env_value != nil do
      env_value
    else
      :not_in_burrito
    end
  end
end
