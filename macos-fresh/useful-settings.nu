# remove dock icons
defaults write com.apple.dock persistent-apps -array

# key repeat interval
defaults write -g KeyRepeat -int 2 # normal minimum is 2 (30 ms)

defaults write -g InitialKeyRepeat -int 15 # normal minimum is 15 (225 ms)

# turn off accent on long press
defaults write -g ApplePressAndHoldEnabled -bool false
