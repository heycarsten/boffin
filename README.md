# Boffin

Dead simple trending / hit counting for Ruby objects using Redis.

## Using it

Configure Boffin if you need to, the defaults are:

```ruby
Boffin.configure do |c|
  c.redis = Redis.connect
  c.namespace = 'boffin'
  c.disable_unique_tracking = false
  c.hours_window_secs  = 1.day
  c.days_window_secs   = 1.month
  c.months_window_secs = 1.year
  c.cache_expire_secs  = 1.hour
end
```

For all configuration stuff check out [lib/boffin/config.rb](https://github.com/heycarsten/boffin/blob/master/lib/boffin/config.rb).

### Use it on models

Include Boffin's insight into any Ruby class that responds to #id:

```ruby
class Listing < My::ORM
  include Boffin::Trackable
  ...
end
```

Boffin will use whatever you give it as uniqueness, for example say you have a
controller action that is only available if a user is logged in, then your hit
call would look like this:

If the object passed in responds to `#as_unique_member` or `#id` it will be used
as an identifier. If the object is a number, string, or symbol `#to_s` is called
and the result is used.

You can pass multiple objects and the first one that is not blank (nil, [], {},
or '') will be used:

If no unique value is available Boffin will make one up for you, or will raise
an error if you are using the strictly unique hit call `#uhit`:

```ruby
get '/listings/:id/map'
  authenticate!
  @listing = Listing.get(params[:id])
  @listing.hit(:view, [current_user])
end
```

Then use Boffin to record hits to the model:

```ruby
get '/listings/:id' do
  @listing = Listing.get(params[:id])
  @listing.hit(:view, [current_user, session.id])
end

put '/listings/:id/like' do
  @listing = Listing.get(params[:id])
  @listing.hit(:like, [current_user, session.id])
end

put '/listings/:id/inquire' do
  @listing = Listing.get(params[:id])
  @listing.hit(:inquiry, [current_user, session.id])
end
```

After some hits have been tracked, you can start to do some queries:

```ruby
# Get count of unique views
@listing.uhit_count(:views)

# Get a raw count of all views ever recorded
@listing.hit_count(:views)

# Get IDs of the most viewed listings in the past 5 days.
Listing.top(:views, days: 5)

# Get IDs of the most liked listings in the past 5 days.
Listing.top(:liked, days: 5)

# Get IDs of the most liked, and viewed listings with likes weighted higher than
# views in the past 5 days.
Listing.trending({ likes: 2, views: 1 }, days: 5)
```

### Use it on anything

```ruby
@tracker = Boffin::Tracker.new

@tracker.hit(:urls, 'http://example.com/mypage', :views, ['session.1'])
@tracker.hit(:listing, @listing, :views)
@tracker.top(:listing, :views, hours: 6)
@tracker.hit_count(:listing, :views)
```
