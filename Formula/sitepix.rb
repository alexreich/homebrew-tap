# Homebrew formula template — tokens are substituted by .github/workflows/release.yml.
# Rendered output lands in your tap repo at Formula/sitepix.rb.
#
# This formula targets macOS. Linux users: install via the .deb/.rpm/AppImage
# from the release page (see README), not Homebrew.
class Sitepix < Formula
  desc "Pulls large photos from WordPress-style news blogs for use as desktop wallpaper"
  homepage "https://github.com/alexreich/SitePix"
  version "1.0.1"
  license "CC-BY-4.0"

  depends_on :macos

  on_arm do
    url "https://github.com/alexreich/SitePix/releases/download/v1.0.1/SitePix-1.0.1-osx-arm64.tar.gz"
    sha256 "4298ccfd7170604bbf733ceb8d977f85b9f7832288041433125ffae006fedc8a"
  end

  on_intel do
    url "https://github.com/alexreich/SitePix/releases/download/v1.0.1/SitePix-1.0.1-osx-x64.tar.gz"
    sha256 "a76451ed744aa6f4e5a9ead35455b4391e98ced133587b4d10299793e57de94d"
  end

  def install
    # Tarballs contain the self-contained .NET publish layout. Drop the whole
    # payload into libexec and expose a thin shim on PATH.
    libexec.install Dir["*"]
    chmod 0755, libexec/"SitePix"
    (bin/"sitepix").write <<~SH
      #!/bin/sh
      exec "#{libexec}/SitePix" "$@"
    SH
    chmod 0755, bin/"sitepix"
  end

  service do
    run [opt_bin/"sitepix"]
    run_type :cron
    cron "30 5 * * *"   # 05:30 daily — edit with `brew services edit sitepix`
    working_dir opt_libexec
    log_path    var/"log/sitepix.log"
    error_log_path var/"log/sitepix.log"
    keep_alive false
  end

  def caveats
    <<~EOS
      SitePix is installed with the bundled kadampa.org profile.

      Run once to populate photos:
        sitepix
        sitepix #{opt_libexec}/samples/petapixel.com.json   # or any other profile

      Start the daily sync (05:30 by default):
        brew services start sitepix
        brew services edit  sitepix      # change the time

      Photos download to ~/Pictures/SitePix by default. Override font, brand
      colors, and source site via JSON profiles — see samples/ inside libexec
      and the README for schema.
    EOS
  end

  test do
    # Just verifies the binary is runnable — real behavior requires network.
    assert_predicate bin/"sitepix", :exist?
    assert_predicate bin/"sitepix", :executable?
  end
end
