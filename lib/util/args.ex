defmodule Burrito.Util.Args do
  @moduledoc """
  This module provides methods to help fetch CLI arguments, whether passed
  down from the Zig wrapper binary or from the system.

  ## The ADO_ARGS fallback

  In some Burrito release configurations (notably `MIX_ENV=prod` cross-
  compiled releases with Zig 0.16.0), the `-extra` arguments passed by
  the Zig wrapper are stripped or reordered by the release config and
  never reach `:init.get_plain_arguments/0`. The Zig wrapper therefore
  sets an `ADO_ARGS` env var containing a space-separated copy of the
  original CLI arguments as a workaround. This module transparently
  falls back to that env var when `:init.get_plain_arguments/0` is
  empty, so downstream apps do not need to change.

  Authors of custom Zig wrappers are encouraged to set `ADO_ARGS` in
  the same way to make their wrappers compatible with this fallback.
  """

  @doc """
  Get CLI arguments passed down from the Zig wrapper binary. Do note that this will get OTP
  runtime arguments when called outside of a Burrito-built context. You may consider
  `argv/0` as a more general alternative.
  """
  @spec get_arguments() :: [String.t()]
  def get_arguments() do
    case :init.get_plain_arguments() |> Enum.map(&to_string/1) do
      [] -> ado_args_from_env()
      args -> args
    end
  end

  @doc """
  Get the arguments from the CLI, regardless if run under Burrito or not.
  """
  @spec argv() :: [String.t()]
  def argv() do
    if Burrito.Util.running_standalone?() do
      get_arguments()
    else
      System.argv()
    end
  end

  @doc """
  Returns the path of the wrapper binary that launched this application.
  If not currently inside a Burrito wrapped application, returns `:not_in_burrito`.
  """
  @spec get_bin_path() :: binary() | :not_in_burrito
  def get_bin_path() do
    env_value = System.get_env("__BURRITO_BIN_PATH")

    if env_value != nil do
      env_value
    else
      :not_in_burrito
    end
  end

  # Split a space-separated ADO_ARGS value into a list of arguments,
  # respecting single and double quotes.
  @spec ado_args_from_env() :: [String.t()]
  defp ado_args_from_env() do
    case System.get_env("ADO_ARGS") do
      nil -> []
      "" -> []
      value -> split_args(value)
    end
  end

  # Minimal POSIX-style argument splitter. Handles single and double
  # quoted segments, and backslash escapes within double quotes.
  defp split_args(str) do
    {tokens, _} =
      str
      |> String.to_charlist()
      |> do_split([], [], false, nil)

    Enum.map(tokens, &List.to_string/1)
  end

  defp do_split([], acc, tokens, _in_quote, _quote_char) do
    {Enum.reverse(flush_token(acc, tokens)), []}
  end

  defp do_split([?\s | rest], acc, tokens, false, _q) do
    do_split(rest, [], flush_token(acc, tokens), false, nil)
  end

  defp do_split([?\\ | rest], acc, tokens, false, _q) do
    do_split(rest, [?\\ | acc], tokens, false, nil)
  end

  defp do_split([c | rest], acc, tokens, false, nil) when c in [?", ?'] do
    do_split(rest, acc, tokens, true, c)
  end

  defp do_split([c | rest], acc, tokens, true, q) when c == q do
    do_split(rest, acc, tokens, false, nil)
  end

  defp do_split([c | rest], acc, tokens, true, q) do
    do_split(rest, [c | acc], tokens, true, q)
  end

  defp do_split([c | rest], acc, tokens, false, _quote_char) do
    do_split(rest, [c | acc], tokens, false, nil)
  end

  defp flush_token([], tokens), do: tokens
  defp flush_token(acc, tokens), do: [Enum.reverse(acc) | tokens]
end
