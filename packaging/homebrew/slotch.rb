# Cask Homebrew pour Slotch.
# Publication : créer un dépôt GitHub « homebrew-tap », y copier ce fichier dans
# Casks/slotch.rb, puis mettre à jour version/sha256 à chaque release
# (release.sh affiche les deux). Installation côté utilisateur :
#   brew install --cask spykoninho/tap/slotch
cask "slotch" do
  version "1.2"
  sha256 "6a2fe3f77e5fed69a8079bfe12451836ad20ab1152bd4f8f9a31387e339bbb55"

  url "https://github.com/Spykoninho/Slotch/releases/download/#{version}/Slotch-#{version}.dmg"
  name "Slotch"
  desc "Slot machine hiding behind your Mac's notch"
  homepage "https://github.com/Spykoninho/Slotch"

  depends_on macos: :monterey

  app "Slotch.app"

  zap trash: [
    "~/Library/Preferences/fr.mathis.slotch.plist",
  ]
end
