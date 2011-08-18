# Boffin

Dead simple trending / hit counting for Ruby objects using Redis.

## Using it

Configure Boffin if you need to, the defaults are:

```ruby
Boffin.configure do |c|
  c.redis = Redis.connect
  c.namespace = 'boffin'
  c.hourly_expire_secs = 1.day   # Hourly resolution for 1 day
  c.daily_expire_secs = 1.month # Daily resolution for 1 month
  c.monthly_expire_secs = 1.year  # Monthly resolution for 1 year
  c.object_id_proc = lambda { |obj| obj.id.to_s }
  c.unique_id_proc = lambda { |obj|
    if obj.respond_to?(:boffin_id)
      obj.boffin_id
    else
      "#{Boffin::Utils.underscore(obj.class)}:#{obj.id}"
    end
  }
end
```

### Use it on models

Include Boffin's insight into any Ruby class that responds to #id:

```ruby
class Listing < My::ORM
  include Boffin::Insights
  ...
end
```

Boffin will use whatever you give it as a unique constraint, for example say
you have a controller action that is only available if a user is logged in, then
your hit call would look like this:

If the object passed in responds to `#boffin_id` it will be used as an
identifier. Otherwise boffin will call `#id` and use that as a unique constraint.

You can pass multiple objects and the first one that is not blank (nil, [], {},
or '') will be used:

If no unique value is available Boffin will make one up for you, or will raise
an error if you are using the strictly unique hit call `#uhit`:

```ruby
get '/listings/:id/map'
  authenticate!
  @listing = Listing.get(params[:id])
  @listing.hit(:map_views, current_user)
end
```

Then use Boffin to record hits to the model:

```ruby
get '/listings/:id' do
  @listing = Listing.get(params[:id])
  @listing.hit(:views, [current_user, session.id])
end

put '/listings/:id/like' do
  @listing = Listing.get(params[:id])
  @listing.hit(:likes, session.id, current_user)
end

put '/listings/:id/inquire' do
  @listing = Listing.get(params[:id])
  @listing.hit(:inquiries, session.id, current_user)
end
```

Boffin will maintain a unique hit count based of the logged-in user, or session
id if a user is not available.

After some data has flowed through your models, you can query them:

```ruby
# Get count of unique views
@listing.unique_hit_count(:views)

# Get a raw count of all views ever recorded
@listing.hit_count(:views)

# Get IDs of the most viewed listings in the past 5 days.
Listing.top_ids(:views, 5)

# Get IDs of the most liked listings in the past 5 days.
Listing.top_ids(:liked, 5)

# Get IDs of the most liked, and viewed listings with likes weighted higher than
# views in the past 5 days.
Listing.combined_top_ids(5, liked: 2, viewed: 1)
```

### Use it on anything

```ruby
Boffin.hit(objspace, object, hitspace, *[unique_identifiers], {meta})
Boffin.hit(:listing, @listing, :views, session[:id])
Boffin.top_ids(:listing, :views, 5)
Boffin.hit_count(:listing, :views)

Boffin.hit_count(:homepage, :views)

Boffin.hit(:page, 'http://example.com/puppies', :views, session[:id])
```
