start-dev:
	@iex --erl "-config dev.config" -S mix

deps:
	@mix deps.get
