defmodule PaperTrail.Mixfile do
  use Mix.Project

  def project do
    [
      app: :paper_trail,
      version: "0.10.1",
      elixir: "~> 1.11",
      description: description(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      applications: [:logger, :ecto, :ecto_sql, :runtime_tools]
    ]
  end

  defp deps do
    [
      {:ecto, ">= 3.4.6"},
      {:ecto_sql, ">= 3.4.5"},
      {:ex_doc, ">= 0.23.0", only: :dev, runtime: false},
      {:postgrex, ">= 0.0.0", only: [:dev, :test]},
      {:jason, ">= 1.2.0", only: [:dev, :test]}
    ]
  end

  defp description do
    """
    Track and record all the changes in your database. Revert back to anytime in history.
    """
  end

  defp package do
    [
      name: :paper_trail,
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Izel Nakri"],
      licenses: ["MIT License"],
      links: %{
        "GitHub" => "https://github.com/izelnakri/paper_trail",
        "Docs" => "https://hexdocs.pm/paper_trail/PaperTrail.html"
      }
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
