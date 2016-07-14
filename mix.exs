defmodule PaperTrail.Mixfile do
  use Mix.Project

  def project do
    [app: :paper_trail,
     version: "0.0.3",
     elixir: "~> 1.3",
     description: description,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: package,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    []
  end

  defp deps do
    [
      {:postgrex, ">= 0.0.0"},
      {:ecto, "~> 2.0.2"},
      {:poison, "2.1.0"}
    ]
  end

  defp description do
     """
     PaperTrail lets you track and record all the changes in your database.
     """
  end

  defp package do
    [
      name: :paper_trail,
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Izel Nakri"],
      licenses: ["MIT License"],
      links: %{
        "GitHub" => "https://github.com/izelnakri/paper_trail"
        # "Docs" => "http://ericmj.github.io/postgrex/"
      }
    ]
  end
end
