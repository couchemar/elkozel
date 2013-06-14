start-dev:
	@iex --erl "-config dev.config" -S mix

get-deps:
	@mix deps.get
