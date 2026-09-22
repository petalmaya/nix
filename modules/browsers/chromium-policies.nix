# Chromium hardening policies (NixOS side). Writes
# /etc/chromium/policies JSON via programs.chromium.extraOpts: no Chromium
# rebuild, binary cache still hits. HM's programs.chromium has no policy
# options, so this can't live in ./chromium.nix.
#
# Names/types checked against Chromium HEAD policy_definitions (Sep 2026,
# chromium 153). Deprecated/removed policies are intentionally absent so
# chrome://policy stays clean.
{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.nixtop.desktop.enable {
    programs.chromium = {
      enable = true;

      # Locked: user cannot override in chrome://settings.
      # 26.05 has no extraOptsRecommended tier (unstable-only), so the last
      # three entries are locked too; move them over when the pin gains it.
      extraOpts = {
        "MetricsReportingEnabled" = false;
        "UrlKeyedAnonymizedDataCollectionEnabled" = false;
        "SafeBrowsingExtendedReportingEnabled" = false;
        "SafeBrowsingSurveysEnabled" = false;
        "SearchSuggestEnabled" = false;
        # 2 = never (0 = always; 1 is deprecated, now behaves as 0).
        "NetworkPredictionOptions" = 2;
        # Exact casing: lowercase-c "SpellcheckServiceEnabled" is unknown.
        "SpellCheckServiceEnabled" = false;
        # 0 = disable browser sign-in.
        "BrowserSignin" = 0;
        "SyncDisabled" = true;
        # Replaces deprecated PromotionalTabsEnabled.
        "PromotionsEnabled" = false;
        "UserFeedbackAllowed" = false;
        "AlternateErrorPagesEnabled" = false;
        "CloudReportingEnabled" = false;
        "PaymentMethodQueryEnabled" = false;
        "HttpsUpgradesEnabled" = true;
        # 1 = Standard (default). 0 = off, 2 = Enhanced phones data home.
        "SafeBrowsingProtectionLevel" = 1;
        "BlockThirdPartyCookies" = true;
        # "secure" breaks captive portals; "automatic" keeps a fallback.
        "DnsOverHttpsMode" = "automatic";
      };
    };
  };
}
