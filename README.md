# Boffin

Hit tracking and reporting of Ruby objects using Redis. Docs are on the way, but
in the meantime please [read the specs](https://github.com/heycarsten/boffin/tree/master/spec/boffin)
for the sweet details that you crave.

## At a glance

```ruby
WordsTracker = Boffin.track(:words, [:searches, :tweets])

post '/tweets' do
  @tweet = Tweet.create(params[:tweet])
  params[:tweet][:body].split.each do |word|
    WordsTracker.hit(:tweets, word, [current_user])
  end
end

post '/search' do
  params[:q]
end
```

Provide a list of valid hit types to ensure you never misspell them:

```ruby
Boffin.track(Listing, [:views, :likes, :shares])
```

Or don't, if that's not how you roll:

```ruby
Boffin.track(Listing)
```

You can also use the mixin directly if that's more your style:

```ruby
class Listing < Sequel::Model
  include Boffin::Trackable
  boffin_tracker.hit_types = [:views, :likes, :shares]

  def as_member
    # Some funky composite key stuff maybe?
    [agent_id, property_id].join('-')
  end
end
```

Boffin will use whatever you give it as uniqueness, for example say you have a
controller action that is only available if a user is logged in, then your hit
call would look like this:

If the object passed in responds to `#as_member` or `#id` it will be used
as an identifier. Otherwise `#to_s` is called and the result is used.

You can pass multiple objects and the first one that is not blank (`nil`, `[]`,
`{}`, or `''`) will be used:

If no unique value is available Boffin will make one up for you, or will raise
an error if you are using the strictly unique hit call `#uhit`:

```ruby
get '/listings/:id/map'
  authenticate!
  @listing = Listing[params[:id]]
  @listing.hit(:views, [current_user])
end
```

Then use Boffin to record hits to the model:

```ruby
get '/listings/:id' do
  @listing = Listing[params[:id]]
  @listing.hit(:views, [current_user, session.id])
end

put '/listings/:id/like' do
  @listing = Listing[params[:id]]
  @listing.hit(:likes, [current_user, session.id])
end

post '/listings/:id/share' do
  @listing = Listing[params[:id]]
  @listing.hit(:shares, [current_user, session.id])
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
Listing.top(:likes, days: 5)

# Get IDs of the most liked, viewed, and shared listings with likes weighted
# higher than views in the past 12 hours.
Listing.top({ likes: 2, views: 1, shares: 3 }, hours: 12)
```

## Use Boffin with anything really

```ruby
@tracker = Boffin::Tracker.new(:colours, [:likes, :dislikes])

@tracker.hit(:likes, 'red')
@tracker.hit(:dislikes, 'blue')
@tracker.hit(:likes, 'green')
@tracker.hit(:dislikes, 'red')
@tracker.hit(:likes, 'green')

@tracker.top(:likes, days: 30)
#=> ["green", "red"]
```

## The Future&trade

 * Documentation!
 * Ability to hit multiple instances in one command
 * Ability to unhit an instance (if a model is destroyed for example.)
 * Ability to get hit-count range for an instance
 * Some nice examples with pretty things.
 * ORM adapters for niceness and tighter integration
 * Reporting DSL thingy
 * Web framework integration (helpers for tracking hits)
 * Ability to blend unique hits with raw hits

## Stuff

Boffin is tested on MRI Ruby 1.9.2

### What's with the name?!?

It's all in [good humour](http://en.wikipedia.org/wiki/Boffin)!

### Are you Brittish?

No, but [this guy](http://github.com/aanand) is :-)
