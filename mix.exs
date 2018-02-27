defmodule Exgpg.Mixfile do
  use Mix.Project

  def project do
    [app: :exgpg,
     version: "0.0.3",
     elixir: "~> 1.0",
     deps: deps(),
     package: package(),
     description: description(),
     source_url: "https://github.com/rozap/exgpg"]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger, :porcelain]]
  end
  
  defp package do
    [
     files: ["config", "lib", "mix.exs", "README.md", "LICENSE*", "test*", "to_import"],
     maintainers: ["Chris Duranti"],
     licenses: ["MIT"],
     links: %{
         "GitHub" => "https://github.com/rozap/exgpg",
     }
    ]
  end
  
  defp description do
    """
    Use gpg from Elixir
    """
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      { :uuid, "~> 1.0" },
      { :porcelain, git: "https://github.com/alco/porcelain.git" }
      # { :porcelain, "~> 2.0"}
    ]
  end
end
