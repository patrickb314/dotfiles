# credlogin.local — service definitions that don't belong in credlogin.sh's
# shared list: ones tied to a single machine, or named after something not
# worth publishing. Sourced at the end of credlogin.sh and installed as
# ~/.credlogin.local.
#
# This file is tracked, so it travels to the sandvault guest home along with
# the rest of the dotfiles. Only ever put `credlogin define` lines here — a
# definition names environment variables and nothing else. Every value stays
# in LastPass under "Shell Logins/<service>/<instance>"; a credential written
# here would be a credential committed.

# to avoid non-zero exit code
true
