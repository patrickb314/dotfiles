#!/bin/sh
# The sandvault account cannot read ~/.config/iterm2, so call the status
# utility inside the iTerm2 bundle, which both accounts can execute, and do
# nothing at all on machines without iTerm2.
CC_STATUS="/Applications/iTerm.app/Contents/Resources/utilities/cc-status"
[ -x "${CC_STATUS}" ] && exec "${CC_STATUS}"
exit 0
