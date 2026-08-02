# Cask Homebrew pour Slotch.
# Publication : créer un dépôt GitHub « homebrew-tap », y copier ce fichier dans
# Casks/slotch.rb, puis mettre à jour version/sha256 à chaque release
# (release.sh affiche les deux). Installation côté utilisateur :
#   brew install --cask spykoninho/tap/slotch
cask "slotch" do
  version "1.0"
  sha256 "REMPLACER_PAR_LE_SHA256_AFFICHE_PAR_RELEASE_SH"

  url "https://github.com/Spykoninho/SlotNotch/releases/download/v#{version}/Slotch-#{version}.dmg"
  name "Slotch"
  desc "Slot machine hiding behind your Mac's notch"
  homepage "https://github.com/Spykoninho/SlotNotch"

  depends_on macos: ">= :monterey"

  app "Slotch.app"

  zap trash: [
    "~/Library/Preferences/fr.mathis.slotch.plist",
  ]
end
