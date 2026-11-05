class_name BuildInfo
extends RefCounted
# The build name shown in Settings and the Home menu. tools/dev/bump_build.sh updates it.
const BUILD := "1.0-dev171"
# Developer build: Settings shows the DEVELOPER section (DevTools). Set false for a store build.
const DEV := false   # off for Rudy's dev166 playtest (he plays it as a new player)
