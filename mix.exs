defmodule Elkozel.Mixfile do
  use Mix.Project

  def project do
    project_options = []
    [ app: :elkozel,
      version: "0.0.1",
      deps: deps,
      elixirc_options: project_options ++ options(Mix.env) ]
  end

  # Configuration for the OTP application
  def application do
    [ registered: [ :kozel_table_sup ],
      mod: {Elkozel, []},
      applications: [ :exlager ] ]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [ {:genx, "0.1", github: "yrashk/genx"},
      {:exlager, github: "khia/exlager"},
          {:goldrush, github: "DeadZen/goldrush", tag: "879c69874a"} ]
 end

  defp options(env) when env in [:dev, :test] do
    [ exlager_level: :debug ]
  end
  defp options(_), do: []
end
