# 7Sage Assignment

Expected language versions:

- Elixir 1.18.3
- Erlang 27.3.2
- But any combination of Elixir > 1.15 and Erlang 25 should probably work

## How to run

Dev Container:
If you use the devcontainer spec, I've included a devcontainer setup that should work out of the box.

Otherwise:

1. Pull down the repository.
2. Ensure Elixir and Erlang are available and compatible, as well as npm to install the single Chart.js dependency.
3. From the project folder, run `npm install --prefix assets`.
4. Run `iex -S mix phx.server` to start the app on port 4000, along with an iex session.
5. Go to http://localhost:4000/ to view the app in the browser.
