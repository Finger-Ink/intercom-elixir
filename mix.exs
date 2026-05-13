defmodule Intercom.Mixfile do
  use Mix.Project

  def project do
    [
      app: :intercom,
      version: "0.1.0",
      elixir: "~> 1.14",
      description: description(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [extra_applications: [:logger, :estree]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:estree, "~> 2.7"},
      {:req, "~> 0.5"},
      {:plug, "~> 1.0", only: :test}
    ]
  end

  defp description do
    "Elixir helpers for generating the Intercom snippet and interacting with the Intercom API"
  end

  defp package do
    [
      name: :intercom,
      files: [
        "lib",
        "priv",
        "mix.exs",
        "README*",
        "readme*",
        "LICENSE*",
        "license*",
        "CHANGELOG*",
        "guides"
      ],
      maintainers: ["Bob Long"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/finger-ink/intercom-elixir",
        "Docs" => "https://github.com/finger-ink/intercom-elixir"
      }
    ]
  end
end
