defmodule ExampleCliApp do
  def start(_, _args) do
    args = Burrito.Util.Args.get_arguments()

    IO.puts("My arguments are: #{inspect(args)}")
    IO.puts("Number of args: #{length(args)}")
    IO.puts("I was started from: #{Burrito.Util.Args.get_bin_path()}")

    test_release_cookie()

    IO.write("Testing Crypto (Generating ed25519 key-pair)...")
    test_crypto()
    IO.write("OK\n")

    IO.write("Testing Sqlite...")
    test_sqlite()
    IO.write("OK\n")

    # Exit with non-zero status if we expected args but got none, so the
    # CI matrix can detect a regression in the wrapper's argument passing.
    expected_args = System.get_env("EXPECTED_ARGS")

    if expected_args do
      expected = String.split(expected_args, " ")
      actual = args

      if Enum.sort(expected) != Enum.sort(actual) do
        IO.puts("ERROR: expected args #{inspect(expected)}, got #{inspect(actual)}")
        System.halt(2)
      end

      IO.puts("Argument check OK: #{length(actual)} args match expected")
    end

    System.halt(0)
  end

  defp test_release_cookie() do
    {:ok, [[cookie_value]]} = :init.get_argument(:setcookie)
    IO.puts("My Release Cookie is: #{inspect(cookie_value)}")
  end

  defp test_crypto() do
    {_pub, _priv} = :crypto.generate_key(:eddsa, :ed25519)
  end

  defp test_sqlite() do
    {:ok, conn} = Exqlite.Sqlite3.open(":memory:")
    :ok = Exqlite.Sqlite3.execute(conn, "create table test (id integer primary key, stuff text)")
    {:ok, statement} = Exqlite.Sqlite3.prepare(conn, "insert into test (stuff) values (?1)")
    :ok = Exqlite.Sqlite3.bind(conn, statement, ["Hello world"])
    :done = Exqlite.Sqlite3.step(conn, statement)
    {:ok, statement} = Exqlite.Sqlite3.prepare(conn, "select id, stuff from test")
    {:row, [1, "Hello world"]} = Exqlite.Sqlite3.step(conn, statement)
    :done = Exqlite.Sqlite3.step(conn, statement)
    :ok = Exqlite.Sqlite3.release(conn, statement)
  end
end
