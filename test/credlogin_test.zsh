#!/bin/zsh
# credlogin.sh: the spec grammar, what a login resolves to, and the shell
# cache that lets a later shell skip LastPass entirely.

source "${0:a:h}/harness.sh"

sandbox_home

source ~/.shprofile
source ~/.shrc >/dev/null

# shrc.sh points cat at bat for interactive use, and ZSH expands an alias when
# it parses a function body, so credlogin.sh has to be read with cat meaning
# cat: the PATH pinned below holds no bat.
unalias cat 2>/dev/null

source ~/.credlogin

# Everything below runs against a PATH with no lpass on it. Nothing here may
# reach the real LastPass account, and a test that quietly started to would
# otherwise look like a passing test.
PATH="${BARE_PATH}"
assert_fails "the tests cannot reach LastPass" quiet_which lpass

# --- the entry grammar --------------------------------------------------

spec_line() { __credlogin_spec_line "$1" }

assert_equal "a bare name is a required stored value" \
  "secret FOO " "$(spec_line 'FOO')"
assert_equal "a trailing ? makes it optional" \
  "optional FOO " "$(spec_line 'FOO?')"
assert_equal "a comma list is one value under several names" \
  "secret A,B,C " "$(spec_line 'A,B,C')"
assert_equal "an = is a fixed value" \
  "literal FOO bar" "$(spec_line 'FOO=bar')"
assert_equal "a fixed value may contain an =" \
  "literal FOO a=b" "$(spec_line 'FOO=a=b')"
assert_equal "a command substitution is run at login" \
  'command FOO gh auth token' "$(spec_line 'FOO=$(gh auth token)')"
assert_equal "a leading - only ever clears" \
  "clear FOO " "$(spec_line '-FOO')"
assert_equal "an @ labels a variant" "variant gh " "$(spec_line '@gh')"
assert_equal "-- separates variants" "--" "$(spec_line '--')"

assert_equal "a + marks a stored value cacheable" \
  "cached_secret FOO " "$(spec_line '+FOO')"
assert_equal "an optional one too" \
  "cached_optional FOO " "$(spec_line '+FOO?')"
assert_equal "and a command-sourced one" \
  'cached_command FOO gh auth token' "$(spec_line '+FOO=$(gh auth token)')"
assert_fails "but a fixed value has nothing to cache" spec_line '+FOO=bar'
assert_fails "and neither does a cleared one" spec_line '+-FOO'
assert_fails "nor a variant label" spec_line '+@gh'

# --- what define accepts ------------------------------------------------

assert_ok "a plain list of names defines a service" \
  credlogin define t_plain FOO BAR
assert_ok "so does one with nothing but fixed values" \
  credlogin define t_fixed FOO=bar
assert_ok "a labelled variant that stores nothing is reachable by name" \
  credlogin define t_labelled FOO -- '@none' BAR=baz

assert_fails "a service name has to be an identifier" \
  credlogin define 9bad FOO
assert_fails "and cannot contain a dash" credlogin define bad-name FOO
assert_fails "a variable name has to be one too" credlogin define t_bad 'FOO-BAR'
assert_fails "define needs at least one entry" credlogin define t_empty
assert_fails "define needs a service name" credlogin define

assert_fails "a spec cannot start with a variant separator" \
  credlogin define t_lead -- FOO
assert_fails "or end with one" credlogin define t_trail FOO --
assert_fails "or hold two in a row" credlogin define t_double FOO -- -- BAR

# An unlabelled variant that requires nothing stored resolves against any
# instance at all, so a mistyped instance would slide into it and look like a
# successful login.
assert_fails "an unlabelled variant requiring nothing is rejected" \
  credlogin define t_catchall FOO -- BAR=baz
assert_fails "a command-sourced variant counts as requiring nothing" \
  credlogin define t_cmd FOO -- 'BAR=$(echo hi)'
assert_fails "a variant label has to look like an instance name" \
  credlogin define t_label FOO -- '@bad name' BAR=baz
assert_fails "and cannot start with a dot" \
  credlogin define t_dot FOO -- '@.hidden' BAR=baz

# add and set prompt for the stored keys, so the field list is what a spec
# reads rather than everything it mentions.
credlogin define t_fields 'A,B' 'C?' D=lit '-E' 'F=$(echo hi)'
assert_equal "the field list is the stored keys, under their first name" \
  "A C" "${_credlogin_t_fields_fields[*]}"
credlogin define t_dupes FOO -- FOO BAR
assert_equal "and names no key twice" "FOO BAR" "${_credlogin_t_dupes_fields[*]}"

assert_ok "a NAME? entry needs no quoting, thanks to the noglob alias" \
  eval 'credlogin define t_noglob FOO?'

# --- reading the notes field --------------------------------------------

NOTES='ALPHA=one
BETA=two=three
GAMMA='

assert_equal "a key is read out of the notes" \
  "one" "$(__credlogin_kv "${NOTES}" ALPHA)"
assert_equal "a value may contain an =" \
  "two=three" "$(__credlogin_kv "${NOTES}" BETA)"
assert_equal "an empty value comes back empty" \
  "" "$(__credlogin_kv "${NOTES}" GAMMA)"
assert_fails "a key that is not there is a miss" \
  __credlogin_kv "${NOTES}" DELTA
assert_fails "and a key is not matched by a prefix of itself" \
  __credlogin_kv "${NOTES}" ALPH

# --- the variables a spec covers ----------------------------------------

credlogin define t_vars '@one' FOO 'BAR?' -- '@two' BAZ QUX=lit '-CONFLICT'
assert_equal "every variable in every variant is covered, labels aside" \
  "FOO BAR BAZ QUX CONFLICT" "$(__credlogin_spec_vars t_vars | tr '\n' ' ' | sed 's/ $//')"

# --- choosing a variant --------------------------------------------------

assert_contains "an instance naming a variant gets that one" \
  "secret BAZ " "$(__credlogin_spec_for t_vars two)"
assert_excludes "and nothing from the others" \
  "secret FOO " "$(__credlogin_spec_for t_vars two)"
assert_fails "a name no variant carries is not a variant" \
  __credlogin_spec_variant t_vars nosuch

# A command hands back the same answer whatever instance was asked for, so an
# unlabelled login must not fall through to one.
assert_excludes "an unlabelled login skips command-sourced variants" \
  "command" "$(__credlogin_spec_for github someinstance)"
assert_contains "but naming one reaches it" \
  "command" "$(__credlogin_spec_for github gh)"

# --- resolving a spec ---------------------------------------------------

resolve() {
  __credlogin_spec_resolve "${CREDLOGIN_SPEC[$1]}" "$2" | tr '\n' '|'
}

credlogin define t_res 'ALPHA,ALIAS' 'BETA?' GAMMA=fixed
assert_equal "a stored value is exported under every name it lists" \
  "ALPHA one|ALIAS one|GAMMA fixed|" "$(resolve t_res 'ALPHA=one')"
assert_equal "an optional value that is stored is used" \
  "ALPHA one|ALIAS one|BETA two|GAMMA fixed|" \
  "$(resolve t_res 'ALPHA=one
BETA=two')"
assert_fails "a required value that is missing fails the whole thing" \
  __credlogin_spec_resolve "${CREDLOGIN_SPEC[t_res]}" 'BETA=two'

credlogin define t_two '@first' ALPHA -- '@second' BETA
assert_equal "variants resolve in order" \
  "ALPHA one|" "$(resolve t_two 'ALPHA=one
BETA=two')"
assert_equal "and a later one carries a login the first cannot" \
  "BETA two|" "$(resolve t_two 'BETA=two')"
assert_fails "with nothing stored, none of them can" \
  __credlogin_spec_resolve "${CREDLOGIN_SPEC[t_two]}" ''

# --- where a cached credential is allowed to land ------------------------

assert_equal "a cache entry sits under the service and instance" \
  "${SHELL_CACHE_DIR}/credlogin/svc/inst" "$(__credlogin_cache_path svc inst)"
assert_ok "a dot or a dash inside an instance name is fine" \
  __credlogin_cache_path svc my-instance.1
assert_fails "an instance name cannot walk up out of the cache" \
  __credlogin_cache_path svc ../../evil
assert_fails "nor contain a slash at all" __credlogin_cache_path svc a/b
assert_fails "nor start with a dot" __credlogin_cache_path svc .hidden
assert_fails "and an empty one is not a name" __credlogin_cache_path svc ""

# --- what gets cached ----------------------------------------------------

cached_file() { echo "${SHELL_CACHE_DIR}/credlogin/$1/$2" }
cache() { __credlogin_cache_write "$1" "$2" "${CREDLOGIN_SPEC[$1]}" "$3" }

credlogin define t_all +ALPHA +BETA
cache t_all inst 'ALPHA=one
BETA=two'
assert_ok "a spec whose values are all cacheable leaves a file behind" \
  test -s "$(cached_file t_all inst)"
assert_file_mode "owner-readable only" 600 "$(cached_file t_all inst)"
assert_equal "holding just the cacheable keys" \
  "ALPHA=one BETA=two" "$(tr '\n' ' ' <"$(cached_file t_all inst)" | sed 's/ $//')"

# Half a login on disk buys nothing: resolving it still ends in the LastPass
# fetch the cache was meant to save.
credlogin define t_mixed +ALPHA BETA
cache t_mixed inst 'ALPHA=one
BETA=two'
assert_fails "a spec mixing cached and uncached values caches nothing" \
  test -e "$(cached_file t_mixed inst)"

credlogin define t_none ALPHA
cache t_none inst 'ALPHA=one'
assert_fails "and one with nothing marked cacheable leaves no file at all" \
  test -e "$(cached_file t_none inst)"

assert_equal "a cached login is read back whole" \
  "ALPHA=one
BETA=two" "$(__credlogin_cached_notes t_all inst "${CREDLOGIN_SPEC[t_all]}")"

# Reckoned from now rather than from whenever shprofile.sh was sourced: the
# entry above was written after that, and a second of drift would leave it
# looking fresh.
WAS="${NOW_EPOCH}"
NOW_EPOCH=$(($(date +%s) + 604800))
assert_fails "and is a miss once it is a week old" \
  __credlogin_cached_notes t_all inst "${CREDLOGIN_SPEC[t_all]}"
NOW_EPOCH="${WAS}"

# --- when LastPass is needed at all --------------------------------------

assert_ok "a stored credential with nothing cached needs LastPass" \
  __credlogin_needs_lastpass t_none inst
assert_fails "one the cache can answer does not" \
  __credlogin_needs_lastpass t_all inst
assert_fails "nor does a variant that stores nothing" \
  __credlogin_needs_lastpass claude subscription
assert_ok "but one that stores something does" \
  __credlogin_needs_lastpass claude api
assert_fails "the gh variant reads the CLI, not LastPass" \
  __credlogin_needs_lastpass github gh
assert_ok "any other github instance reads LastPass" \
  __credlogin_needs_lastpass github sandbox
assert_ok "a hand-written service with fields needs it too" \
  __credlogin_needs_lastpass ssh mykey

# --- logging in and out --------------------------------------------------

assert_equal "nothing is logged in to start with" \
  "credlogin: no active logins" "$(credlogin status)"

assert_fails "login needs a service" credlogin login
assert_fails "and rejects one that is not defined" credlogin login nosuch inst
assert_fails "a stored service still needs an instance" credlogin login t_none
assert_fails "logout of a service that is not logged in fails" \
  credlogin logout t_all
assert_fails "logout needs a service too" credlogin logout
assert_contains "an unknown verb prints the usage" \
  "credlogin <verb>" "$(credlogin frobnicate 2>&1)"
assert_contains "so does no verb at all" \
  "credlogin <verb>" "$(credlogin 2>&1)"

assert_contains "list names the services that are defined" \
  "firecrawl" "$(credlogin list)"
assert_contains "including the hand-written one" "ssh" "$(credlogin list)"
assert_fails "listing one service's instances needs LastPass" \
  credlogin list github

assert_fails "add rejects a service that is not defined" \
  credlogin add nosuch inst
assert_fails "add needs an instance" credlogin add t_all
assert_fails "and needs LastPass" credlogin add t_all inst

# A login the cache can carry on its own goes through with no LastPass
# session anywhere in sight.
# Run in this shell rather than through assert_ok, which would export into a
# command substitution and throw the result away.
unset ALPHA BETA
credlogin login t_all inst
assert_equal "a cached login succeeds with no LastPass session" "0" "$?"
assert_equal "exporting the stored value" "one" "${ALPHA}"
assert_equal "and the rest of them" "two" "${BETA}"
assert_equal "status reports the instance" \
  "t_all -> inst" "$(credlogin status)"
credlogin logout t_all
assert_equal "logout succeeds" "0" "$?"
assert_empty "and unsets what login exported" "${ALPHA}${BETA}"
assert_equal "leaving nothing active" \
  "credlogin: no active logins" "$(credlogin status)"

# Nothing is exported until a variant comes out whole, so a login that cannot
# be resolved leaves the shell exactly as it found it.
export ALPHA=untouched
credlogin login t_none inst 2>/dev/null
assert_unequal "a login that cannot reach LastPass fails" "0" "$?"
assert_equal "and leaves the environment alone" "untouched" "${ALPHA}"
unset ALPHA

# Switching instances must not leave a value behind from the shape that was
# active before, so login clears every variable the spec mentions first.
credlogin define t_switch '@a' +ALPHA -- '@b' +BETA
cache t_switch a 'ALPHA=one'
cache t_switch b 'BETA=two'
credlogin login t_switch a
assert_equal "a labelled variant exports its own value" "one" "${ALPHA}"
credlogin login t_switch b
assert_equal "switching instances exports the new one" "two" "${BETA}"
assert_empty "and clears the one from the shape before it" "${ALPHA}"
credlogin logout t_switch
unset ALPHA BETA

# --- the services that ship with it --------------------------------------

resolve_for() {
  __credlogin_spec_resolve "$(__credlogin_spec_for "$1" "$2")" "$3" | tr '\n' '|'
}

assert_equal "a github token is exported under both names" \
  "GITHUB_TOKEN abc|GH_TOKEN abc|" "$(resolve_for github sandbox 'GITHUB_TOKEN=abc')"
assert_contains "the claude subscription variant pins the proxy off" \
  "CLAUDE_CODE_USE_FOUNDRY 0" "$(resolve_for claude subscription '')"
assert_contains "the foundry variant pins it on" \
  "CLAUDE_CODE_USE_FOUNDRY 1" \
  "$(resolve_for claude foundry 'ANTHROPIC_FOUNDRY_API_KEY=k
ANTHROPIC_FOUNDRY_BASE_URL=u')"
assert_equal "the api variant is one key and nothing else" \
  "ANTHROPIC_API_KEY k|" "$(resolve_for claude api 'ANTHROPIC_API_KEY=k')"
assert_equal "zotero gets by without a library type" \
  "ZOTERO_API_KEY k|ZOTERO_LIBRARY_ID 1|" \
  "$(resolve_for zotero personal 'ZOTERO_API_KEY=k
ZOTERO_LIBRARY_ID=1')"

# --- sourcing it twice ---------------------------------------------------

# ZSH expands aliases as it parses, so on a re-source the alias defined part
# way down the file would otherwise turn the function's own name into
# `noglob credlogin` and leave the definition broken.
assert_ok "re-sourcing an already-loaded shell works" \
  eval 'source ~/.credlogin && source ~/.credlogin'
assert_equal "and leaves credlogin working" \
  "credlogin: no active logins" "$(credlogin status)"
assert_contains "with the noglob alias back in place" \
  "noglob credlogin" "$(alias credlogin)"

finish
