Boffin
======

Hit tracking library for Ruby using [Redis](http://redis.io)

About
-----

Boffin is a library for tracking hits to things in your Ruby application. Things
can be IDs of records in a database, strings representing tags or topics, URLs
of webpages, names of places, whatever you desire. Boffin is able to provide
lists of those things based on most hits, least hits, it can even report on
weighted combinations of different types of hits.

Resources
---------

 * [Documentation](http://rubydoc.info/github/heycarsten/boffin/master/frames)
 * [Source Code](https://github.com/heycarsten/boffin)
 * [Issue Tracker](https://github.com/heycarsten/boffin/issues)
 * [Test Suite](https://github.com/heycarsten/boffin/tree/master/spec)
 * [License](https://github.com/heycarsten/boffin/blob/master/LICENSE)

Getting started
---------------

You need a functioning [Redis](http://redis.io) installation. Once Redis is
installed you can start it by running `redis-server`, this will run Redis in the
foreground.

You can use Boffin in many different contexts, but the most common one is
probably that of a Rails or Sinatra application. Just add `boffin` to your
[Gemfile](http://gembundler.com):

```ruby
gem 'boffin'
```

For utmost performance on *nix-based systems, require
[hiredis](https://github.com/pietern/hiredis-rb) before you require Boffin:

```ruby
gem 'hiredis'
gem 'boffin'
```

Configuration
-------------

Most of Boffin's default configuration options are quite reasonable, but they
are easy to change if required:

```ruby
Boffin.config do |c|
  c.redis              = MyApp.redis             # Redis.connect by default
  c.namespace          = "tracking:#{MyApp.env}" # Redis key namespace
  c.hours_window_secs  = 3.days     # Time to maintain hourly interval data
  c.days_window_secs   = 3.months   # Time to maintain daily interval data
  c.months_window_secs = 3.years    # Time to maintain monthly interval data
  c.cache_expire_secs  = 15.minutes # Time to cache Tracker#top result sets
end
```

Tracking
--------

A Tracker is responsible for maintaining a namespace for hits. For our examples
we will have a model called `Listing` it represents a listing in our realty
web app. We want to track when someone likes, shares, or views a listing.

Our example web app uses [Sinatra](http://sinatrarb.com) as its framework, and
[Sequel](http://sequel.rubyforge.org)::Model as its ORM. It's important to note
that Boffin has no requirements on any of these things, it can be used to track
any Ruby class in any environment.

Start by telling Boffin to make the Listing model trackable:

```ruby
Boffin.track(Listing)
```

**_or_**

```ruby
class Listing < Sequel::Model
  include Boffin::Trackable
end
```

You can optionally specify the types of hits that are acceptable, this is good
practice and will save frustrating moments where you accidentally type `:view`
instead of `:views`, to do that:

```ruby
Boffin.track(Listing, [:likes, :shares, :views])
```

**_or_**

```ruby
class Listing < Sequel::Model
  include Boffin::Trackable
  boffin.hit_types = [:likes, :shares, :views]
end
```

**_or_**

```ruby
class Listing < Sequel::Model
  Boffin.track(self, [:likes, :shares, :views])
end
```

Now to track hits on instances of the Listing model, simply:

```ruby
get '/listings/:id' do
  @listing = Listing[params[:id]]
  @listing.hit(:views)
  haml :'listings/show'
end
```

However you will probably want to provide Boffin with some uniqueness to
identify hits from particular users or sessions:

```ruby
get '/listings/:id' do
  @listing = Listing[params[:id]]
  @listing.hit(:views, unique: [current_user, session[:id]])
  haml :'listings/show'
end
```

Boffin now adds uniqueness to the hit in the form of `current_user.id` if
available. If `current_user` is nil, Boffin then uses `session[:id]`. You can
provide as many uniquenesses as you'd like, the first one that is not blank
(`nil`, `false`, `[]`, `{}`, or `''`) will be used.

It could get a bit tedious having to add `[current_user, session[:id]]` whenever
we want to hit an instance, so let's create a helper:

```ruby
helpers do
  def hit(trackable, type)
    trackable.hit(type, unique: [current_user, session[:id]])
  end
end
```

For these examples we are in the context of a Sinatra application, but this is
applicable to a Rails application as well:

```ruby
class ApplicationController < ActionController::Base
  protected
  def hit(trackable, type)
    trackable.hit(type, unique: [current_user, session[:session_id]])
  end
end
```

You get the idea, now storing a hit is as easy as:

```ruby
get '/listings/:id' do
  @listing = Listing[params[:id]]
  hit @listing, :views
  haml :'listings/show'
end
```

Reporting
---------

After some hits have been tracked, you can start to do some queries:

**Get a count of all views for an instance**

```ruby
@listing.hit_count(:views)
```

**Get count of unique views for an instance**

```ruby
@listing.hit_count(:views, unique: true)
```

**Get IDs of the most viewed listings in the past 5 days**

```ruby
Listing.top_ids(:views, days: 5)
```

**Get IDs of the least viewed listings (that were viewed) in the past 8 hours**

```ruby
Listing.top_ids(:views, hours: 8, order: 'asc')
```

**Get IDs and hit counts of the most liked listings in the past 5 days**

```ruby
Listing.top_ids(:likes, days: 5, counts: true)
```

**Get IDs of the most liked, viewed, and shared listings with likes weighted
higher than views in the past 12 hours**

```ruby
Listing.top_ids({ likes: 2, views: 1, shares: 3 }, hours: 12)
```

**Get IDs and combined/weighted scores of the most liked, and viewed listings in
the past 7 days**

```ruby
Listing.top_ids({ likes: 2, views: 1 }, hours: 12, counts: true)
```

Boffin records hits in time intervals: hours, days, and months. Each interval
has a window of time that it is available before it expires; these windows are
configurable. It's also important to note that the results returned by these
methods are cached for the duration of `Boffin.config.cache_expire_secs`. See
**Configuration** above.

More
====

Not just for models
-------------------

As stated before, you can use Boffin to track anything. Maybe you'd like to
track your friends' favourite and least favourite colours:

```ruby
@tracker = Boffin::Tracker.new(:colours, [:faves, :unfaves])

@tracker.hit(:faves,   'red',    unique: ['lena'])
@tracker.hit(:unfaves, 'blue',   unique: ['lena'])
@tracker.hit(:faves,   'green',  unique: ['soren'])
@tracker.hit(:unfaves, 'red',    unique: ['soren'])
@tracker.hit(:faves,   'green',  unique: ['jens'])
@tracker.hit(:unfaves, 'yellow', unique: ['jens'])

@tracker.top(:faves, days: 1)
```

Or, perhaps you'd like to clone Twitter? Using Boffin, all the work is
essentially done for you*:

```ruby
WordsTracker = Boffin::Tracker.new(:words, [:searches, :tweets])

get '/search' do
  @tweets = Tweet.search(params[:q])
  params[:q].split.each { |word| WordsTracker.hit(:searches, word) }
  haml :'search/show'
end

post '/tweets' do
  @tweet = Tweet.create(params[:tweet])
  if @tweet.valid?
    @tweet.words.each { |word| WordsTracker.hit(:tweets, word) }
    redirect to("/tweets/#{@tweet.id}")
  else
    haml :'tweets/form'
  end
end

get '/trends' do
  @words = WordsTracker.top({ tweets: 3, searches: 1 }, hours: 5)
  haml :'trends/index'
end
```
_*This is a joke._


Custom increments
-----------------

For some applications you might want to track something beyond simple hits.
To accomodate this you can specify a custom increment to any hit you record.
For example, if you run an ecommerce site it might be nice to know which
products are your bestsellers:

```ruby
class Product < ActiveRecord::Base
  Boffin.track(self, [:sales])
end

class Order < ActiveRecord::Base
  after_create :track_sales

  private

  def track_sales
    line_items.each do |line_item|
      product = line_item.product
      amount  = product.amount.cents * line_item.quantity
      product.hit :sales, increment: amount
    end
  end
end
```

Then, when you want to check on your sales over the last day:

```ruby
Product.top_ids(:sales, hours: 24, counts: true)
```

The Future&trade;
-----------------

 * Ability to hit multiple instances in one command
 * Ability to get hit-count range for an instance
 * Some nice examples with pretty things
 * Maybe ORM adapters for niceness and tighter integration
 * Examples of how to turn IDs back into instances
 * Reporting DSL thingy
 * Web framework integration (helpers for tracking hits, console type ditty.)
 * Ability to union on unique hits and raw hits

FAQ
---

### What's with the name?

Well, it means [this](http://en.wikipedia.org/wiki/Boffin). For the purposes of
this project, its use is very tongue-in-cheek.

### Are you British?

No, I'm just weird, but [this guy](http://github.com/aanand) is a real British person.
