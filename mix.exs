defmodule Elkozel.Mixfile do
  use Mix.Project

  def project do
    [ app: :elkozel,
      version: "0.0.1",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    [ registered: [:kozel_table_sup],
      mod: {Elkozel, []} ]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [ {:genx, "0.1", github: "yrashk/genx"} ]
  end
end
