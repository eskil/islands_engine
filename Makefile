# Remember, this evaluates before any build rules.
ifeq ($(shell which iex),)
  $(error "No iex in $(PATH), run 'brew install elixir'")
endif

.PHONY: test

all:
	mix deps.get
	mix

clean:
	mix clean

pure:
	mix deps.clean --all
	mix clean

test:
	MIX_ENV=test mix coveralls.html --trace
	MIX_ENV=test mix test
