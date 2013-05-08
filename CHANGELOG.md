1.0.0

 * Support for redis-rb 3.0, no backwards compatibility is maintained
 * Ruby 2.0 is now officially supported, 1.9.3, and 1.8.7 are still supported
 * Removed `Tracker#uhit_count` in favour of `Tracker#count(..., unique: true)`
 * Renamed `Utils#object_as_session_identifier` to `Utils#object_as_uid`
 * Renamed `Tracker#hit_count` to `Tracker#count`
 * Renamed `Utils#uniquenesses_as_session_identifier` to `Utils#uniquenesses_as_uid`
 * Changed `Utils#uniquenesses_as_uid` to splat arguments, this allows for uses
   like `Tracker.hit(:thing, unique: current_user)` instead of
   `Tracker.hit(:thing, unique: [current_user])`
 * Removed `Tracker#hit_count_for_session_id` in favour of
   `Tracker#count(..., unique: unique_object)`

0.3.0

 * `Hit` can now accept a custom increment, this allows values such as cents to
   be tracked (Justin Giancola)
 * Unique qualities are now passed in as a member in an options hash for
   `Tracker#hit`, this deprecates the unique qualities argument and allows for
   other options such as `:increment` to be passed as well (Justin Giancola)

0.2.0

 * Support for Ruby 1.8.7 (Justin Giancola)

0.1.0

 * Initial public release
