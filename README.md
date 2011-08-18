# Boffin

Dead simple trending / hit counting for Ruby objects using Redis.

## Using it

Configure Boffin if you need to, the defaults are:

```ruby
Boffin.redis = Redis.connect
Boffin.redis_namespace = 'boffin'
Boffin.expire_daily_hits_after_seconds = 7776000 # 3 months
Boffin.expire_cached_unions_after_seconds = 3600 # 1 hour
```

Require Boffin's insightfulness into any Ruby class that responds to #id:

```ruby
class Listing < My::ORM
  include Boffin::Insights
  ...
end
```

Then use Boffin to record hits to your model:

```ruby
get '/listings/:id' do
  @listing = Listing.get(params[:id])
  @listing.hit(:views, session.id, current_user)
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
Listing#hit_count(:views)

# Get a raw count of all views ever recorded
Listing#raw_hit_count(:views)

# Get IDs of the most viewed listings in the past 5 days.
Listing.top_ids(:views, 5)

# Get IDs of the most liked listings in the past 5 days.
Listing.top_ids(:liked, 5)

# Get IDs of the most liked, and viewed listings with likes weighted higher than
# views in the past 5 days.
Listing.combined_top_ids(5, liked: 2, viewed: 1)
```

# Problems / Pending Improvements

 * Hit resolution is set to days, in the future hours, days, months, years will
   all be available.
 * 
