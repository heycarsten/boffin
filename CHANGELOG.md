**0.3.0**

 * `Hit` can now accept a custom increment, this allows values such as cents to
   be tracked. (Justin Giancola)
 * Unique qualities are now passed in as a member in an options hash for
   `Tracker#hit`, this deprecates the unique qualities argument and allows for
   other options such as `:increment` to be passed as well. (Justin Giancola)

**0.2.0**

 * Support for Ruby 1.8.7 thanks to Justin Giancola

**0.1.0**

 * Initial public release
