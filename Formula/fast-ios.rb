class FastIos < Formula
  desc "Light iOS simulators: one switch, and a simulator pool for agents"
  homepage "https://github.com/aaryanporwal/fast-ios"
  url "https://github.com/aaryanporwal/fast-ios/archive/refs/tags/v0.4.0.tar.gz"
  sha256 "dc595334924d6994a5f8c2282ec4a2378a586ddb0f269f9c4d3a0cd9e23ab7eb"
  license "MIT"
  head "https://github.com/aaryanporwal/fast-ios.git", branch: "main"

  # Swift 6.3 is the minimum (Package.swift); Xcode 26.6 is the oldest CI proves.
  depends_on xcode: ["26.6", :build]
  depends_on macos: :sequoia

  def install
    # Homebrew's build sandbox cannot nest SwiftPM's own sandbox.
    system "swift", "build", "--disable-sandbox", "-c", "release"
    bin_path = Utils.safe_popen_read("swift", "build", "--disable-sandbox", "-c", "release", "--show-bin-path").chomp

    # Menu-bar app: the same layout as scripts/bundle-app.sh, for this Mac's
    # architecture only. Copy the tool into it before bin.install, which moves
    # the file.
    app = prefix/"fast-ios.app/Contents"
    (app/"MacOS").mkpath
    (app/"Resources").mkpath
    cp "#{bin_path}/FastIOSBar", app/"MacOS/FastIOSBar"
    cp "#{bin_path}/fast-ios", app/"MacOS/fast-ios"
    cp %w[packaging/app/AppIcon.icns packaging/app/MenuBarIcon.png packaging/app/MenuBarIcon@2x.png
          THIRD_PARTY_NOTICES.md THIRD_PARTY_SIMSLIM_LICENSE LICENSE], app/"Resources"
    (app/"Info.plist").write <<~PLIST
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>CFBundleDevelopmentRegion</key><string>en</string>
        <key>CFBundleDisplayName</key><string>fast-ios</string>
        <key>CFBundleExecutable</key><string>FastIOSBar</string>
        <key>CFBundleIconFile</key><string>AppIcon</string>
        <key>CFBundleIdentifier</key><string>dev.fast-ios.app</string>
        <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
        <key>CFBundleName</key><string>fast-ios</string>
        <key>CFBundlePackageType</key><string>APPL</string>
        <key>CFBundleShortVersionString</key><string>#{version}</string>
        <key>CFBundleVersion</key><string>#{version}</string>
        <key>LSApplicationCategoryType</key><string>public.app-category.developer-tools</string>
        <key>LSMinimumSystemVersion</key><string>15.0</string>
        <key>LSUIElement</key><true/>
        <key>NSHumanReadableCopyright</key><string>MIT licence. Tiger from page-mascot by Kamran Ahmed (MIT).</string>
      </dict>
      </plist>
    PLIST
    system "codesign", "--force", "--sign", "-", app/"MacOS/fast-ios"
    system "codesign", "--force", "--sign", "-", prefix/"fast-ios.app"

    bin.install "#{bin_path}/fast-ios"
  end

  def caveats
    <<~EOS
      The menu-bar app is installed at:
        #{opt_prefix}/fast-ios.app
      Open it with:
        open #{opt_prefix}/fast-ios.app
      To keep it in Launchpad and Spotlight, link it into Applications:
        ln -sf #{opt_prefix}/fast-ios.app ~/Applications/fast-ios.app
    EOS
  end

  test do
    assert_match "light iOS simulators", shell_output("#{bin}/fast-ios help")
    assert_match "Off means:", shell_output("#{bin}/fast-ios catalog")
  end
end
