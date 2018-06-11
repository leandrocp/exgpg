defmodule Exgpg do
  require Logger

  @global_args [no_use_agent: true, batch: true, no_default_keyring: true, trust_model: :always]

  @without_input [
    list_key: [{:with_colons, true} | @global_args],
    version: []
  ]

  @with_input [
    gen_key: [],
    encrypt: @global_args,
    decrypt: @global_args,
    symmetric: @global_args,
    verify: @global_args,
    sign: @global_args
  ]


  Enum.each(@without_input, fn {command, args} ->
    def unquote(command)(user_args \\ [], opts \\ []) do
      args = [{unquote(command), true} | unquote(args)]
      {nil, args, user_args, opts}
      |> run(unquote(command))
      |> adapt_out(unquote(command))
    end
  end)

  Enum.each(@with_input, fn {command, args} ->
    def unquote(command)(input \\ nil, user_args \\ [], opts \\ []) do
      args = [{unquote(command), true} | unquote(args)]
      {input, args, user_args, opts}
      |> adapt_in(unquote(command))
      |> run(unquote(command))
      |> adapt_out(unquote(command))
    end
  end)

  def export_key(email, args \\ [], opts \\ []) do
    run({nil, args, [{:export, email}], opts}, :ok)
  end

  def import_key(input, user_args \\ [], opts \\ []) do
    run({input, [{:'import', true} | @global_args], user_args, opts}, :ok)
  end

  defp run({nil, args, user_args, opts}, _) do
    spawn_opts = [out: :stream, err: :string]
    gpg(args, user_args, spawn_opts, opts)
  end

  defp run({input, args, user_args, opts}, _) do
    spawn_opts = [in: input, out: :stream, result: :keep, err: :string]
    gpg(args, user_args, spawn_opts, opts)
  end

  defp gpg(args, user_args, spawn_opts, opts) do
    argv = args
    |> Enum.concat(user_args)
    |> OptionParser.to_argv

    if debug?(opts) do
      Logger.info "#{gpg_bin_path(opts)} #{Enum.join(argv, " ")}"
    end

    Porcelain.spawn(gpg_bin_path(opts), argv, spawn_opts)
  end

  def debug?(opts), do: Keyword.get(opts, :debug, false)

  def gpg_bin_path(args) do
    Keyword.get(args, :gpg_bin_path) || System.find_executable("gpg")
  end

  def adapt_in({input, _args, _user_args, opts}, :gen_key) do
    input = input
    |> Enum.filter(fn {key, _} -> key != :gen_key end)    
    |> Enum.map(fn {key, val} -> {Atom.to_string(key), val} end)
    |> Enum.map(fn {key, val} -> to_genkey(key, val) end)
    |> Enum.join("\n")
    {input, [{:gen_key, true} | @global_args], [], opts}
  end

  def adapt_in({input, args, user_args, opts}, _), do: {input, args, user_args, opts}

  def adapt_out(result, :list_key) do
    result.out
    |> Enum.into("")
    |> String.split("\n")
    |> Enum.drop(1)
    |> Enum.map(fn s ->
      s
      |> String.split(":")
      |> Enum.filter(&(&1 != ""))
    end)
    |> Enum.filter(&(&1 != []))
    |> Enum.chunk(2)
    |> Enum.map(&(List.to_tuple &1))
  end

  def adapt_out(proc, :verify) do
    Porcelain.Process.await(proc, 1000)
  end

  def adapt_out(proc, :gen_key) do
    Porcelain.Process.await(proc, 100_000)
  end

  def adapt_out(proc, _), do: proc


  defp to_genkey("ctrl_" <> rest, ""), do: "%" <> rest
  defp to_genkey("ctrl_" <> rest, val) do
    ("%" <> rest) <> (" " <> val)
  end

  defp to_genkey(key, val) do
    (key
     |> String.split("_")
     |> Enum.map(&String.capitalize &1)
     |> Enum.join("-")) <> (": " <> "#{val}")
  end

end
