# Agraledger

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Continuous integration

CI runs on Woodpecker (`.woodpecker.yml`). The clone step reads the following secrets:

* `forgejo_user` / `forgejo_token` — credentials for the Forgejo clone.
* `forgejo_host` — Forgejo Git host (and port) used to construct the clone URL. Optional; defaults to `forgejo:3000` when the secret is unset.

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
