defmodule Burrito.Util.ArgsTest do
  use ExUnit.Case, async: false

  alias Burrito.Util.Args

  # The public API of `get_arguments/0` is: try :init.get_plain_arguments/0
  # first, fall back to ADO_ARGS env var. We test both paths separately.

  describe "get_bin_path/0" do
    test "returns env value when set" do
      System.put_env("__BURRITO_BIN_PATH", "/path/to/binary")
      assert Args.get_bin_path() == "/path/to/binary"
    end

    test "returns :not_in_burrito when unset" do
      System.delete_env("__BURRITO_BIN_PATH")
      assert Args.get_bin_path() == :not_in_burrito
    end
  end

  # The private split_args/1 + ado_args_from_env/0 logic is tested via the
  # public get_arguments/0 path. We need to ensure :init.get_plain_arguments/0
  # returns [] in this test environment, otherwise the fallback isn't hit.
  # In a non-Burrito BEAM session started without `-extra` flags, it should
  # return [].
  describe "get_arguments/0 ADO_ARGS fallback" do
    setup do
      original = System.get_env("ADO_ARGS")

      on_exit(fn ->
        if original,
          do: System.put_env("ADO_ARGS", original),
          else: System.delete_env("ADO_ARGS")
      end)

      :ok
    end

    test "returns [] when ADO_ARGS is unset" do
      System.delete_env("ADO_ARGS")
      # Only run this check if :init.get_plain_arguments/0 actually returns []
      # in the current environment (typical for `mix test`)
      if :init.get_plain_arguments() == [] do
        assert Args.get_arguments() == []
      end
    end

    test "returns [] when ADO_ARGS is empty" do
      System.put_env("ADO_ARGS", "")

      if :init.get_plain_arguments() == [] do
        assert Args.get_arguments() == []
      end
    end

    test "splits ADO_ARGS on spaces" do
      System.put_env("ADO_ARGS", "arg1 arg2 arg3")

      if :init.get_plain_arguments() == [] do
        assert Args.get_arguments() == ["arg1", "arg2", "arg3"]
      end
    end

    test "preserves double-quoted segments" do
      System.put_env("ADO_ARGS", ~s(--name "John Doe" --age 30))

      if :init.get_plain_arguments() == [] do
        assert Args.get_arguments() == ["--name", "John Doe", "--age", "30"]
      end
    end

    test "preserves single-quoted segments" do
      System.put_env("ADO_ARGS", ~s(--name 'John Doe' --age 30))

      if :init.get_plain_arguments() == [] do
        assert Args.get_arguments() == ["--name", "John Doe", "--age", "30"]
      end
    end

    test "preserves empty quoted string" do
      System.put_env("ADO_ARGS", ~s(a "" b))

      if :init.get_plain_arguments() == [] do
        assert Args.get_arguments() == ["a", "", "b"]
      end
    end

    test "handles mixed quoted/unquoted segments" do
      System.put_env("ADO_ARGS", ~s(foo "bar baz" qux))

      if :init.get_plain_arguments() == [] do
        assert Args.get_arguments() == ["foo", "bar baz", "qux"]
      end
    end
  end
end
