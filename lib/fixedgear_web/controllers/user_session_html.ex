defmodule FixedGearWeb.UserSessionHTML do
  use FixedGearWeb, :html

  embed_templates "user_session_html/*"

  defp local_mail_adapter? do
    Application.get_env(:fixedgear, FixedGear.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
