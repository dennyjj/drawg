cask "drawg" do
  version "1.0.0"
  sha256 "REPLACE_WITH_SHA256"

  url "https://github.com/dennyjj/drawg/releases/download/v#{version}/Drawg.zip"
  name "Drawg"
  desc "Screenshot and annotation tool for macOS"
  homepage "https://github.com/dennyjj/drawg"

  depends_on macos: ">= :ventura"

  app "Drawg.app"

  zap trash: [
    "~/.drawg",
  ]
end
