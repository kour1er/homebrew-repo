cask "lingon-x-dev" do
  if MacOS.version <= :high_sierra
    version "6.6.5"
    sha256 "b0231b1a98dcc8f5c4234b419c9f5331407b8cce29b33f0ea2e32b12595adfa8"
  else
    version "8.4"
    sha256 "4cba73dcf80ee753f66904013d5bce5277046760d3bb36488c19f8aac85aae48"
  end

  url "https://www.peterborgapps.com/downloads/LingonX#{version.major}.zip"
  name "Lingon X"
  desc "Automator software to start apps, run scripts or commands and more"
  homepage "https://www.peterborgapps.com/lingon/"

  livecheck do
    url "https://www.peterborgapps.com/updates/lingonx#{version.major}.plist"
    strategy :page_match
    regex(%r{<key>version</key>\s*\n\s*<string>(\d+(?:\.\d+)*)</string>}i)
  end

  depends_on macos: ">= :high_sierra"

  app "Lingon X.app"

  zap trash: [
    "~/Library/Application Scripts/com.peterborgapps.LingonX#{version.major}",
    "~/Library/Application Support/Lingon X",
    "~/Library/Containers/com.peterborgapps.LingonX#{version.major}",
  ]
end
