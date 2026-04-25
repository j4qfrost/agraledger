defmodule AgraledgerWeb.Router do
  use AgraledgerWeb, :router

  import AgraledgerWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AgraledgerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Public landing redirects to login or dashboard
  scope "/", AgraledgerWeb do
    pipe_through :browser

    # No public routes — root is in the viewer live_session below
  end

  # Other scopes may use custom stacks.
  # scope "/api", AgraledgerWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:agraledger, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AgraledgerWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", AgraledgerWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{AgraledgerWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  ## Application routes

  # Read-only — viewers, bookkeepers, admins
  scope "/", AgraledgerWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :viewer,
      on_mount: [
        {AgraledgerWeb.UserAuth, :require_authenticated},
        {AgraledgerWeb.RoleHelper, :require_viewer}
      ] do
      live "/", DashboardLive, :index
      live "/vendors", VendorLive.Index, :index
      live "/vendors/:id", VendorLive.Show, :show
      live "/contacts", ContactLive.Index, :index
      live "/contacts/:id", ContactLive.Show, :show
      live "/products", ProductLive.Index, :index
      live "/products/:id", ProductLive.Show, :show
      live "/supply-chain", SupplyChainLive, :index
      live "/ledger/accounts", AccountLive.Index, :index
      live "/ledger/entries", JournalEntryLive.Index, :index
      live "/ledger/entries/:id", JournalEntryLive.Show, :show
      live "/reports/trial-balance", ReportLive.TrialBalance, :index
      live "/reports/balance-sheet", ReportLive.BalanceSheet, :index
      live "/reports/income-statement", ReportLive.IncomeStatement, :index
    end
  end

  # Bookkeeper writes
  scope "/", AgraledgerWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :bookkeeper,
      on_mount: [
        {AgraledgerWeb.UserAuth, :require_authenticated},
        {AgraledgerWeb.RoleHelper, :require_bookkeeper}
      ] do
      live "/vendors/new", VendorLive.Form, :new
      live "/vendors/:id/edit", VendorLive.Form, :edit
      live "/contacts/new", ContactLive.Form, :new
      live "/contacts/:id/edit", ContactLive.Form, :edit
      live "/products/new", ProductLive.Form, :new
      live "/products/:id/edit", ProductLive.Form, :edit
      live "/ledger/entries/new", JournalEntryLive.Form, :new
      live "/ledger/entries/:id/edit", JournalEntryLive.Form, :edit
    end
  end

  # Admin only
  scope "/", AgraledgerWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :admin,
      on_mount: [
        {AgraledgerWeb.UserAuth, :require_authenticated},
        {AgraledgerWeb.RoleHelper, :require_admin}
      ] do
      live "/admin/users", AdminLive.UserIndex, :index
      live "/admin/fiscal-periods", AdminLive.FiscalPeriodIndex, :index
    end
  end

  scope "/", AgraledgerWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{AgraledgerWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
