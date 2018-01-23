# Draftsman v0.8.dev

[![Build Status](https://travis-ci.org/jmfederico/draftsman.svg?branch=master)](https://travis-ci.org/jmfederico/draftsman)

Draftsman is a Ruby gem that lets you create draft versions of your database
records. If you're developing a system in need of simple drafts or a publishing
approval queue, then Draftsman just might be what you need.

-  The largest risk at this time is functionality that assists with publishing
   or reverting dependencies through associations (for example, "publishing" a
   child also publishes its parent if it's a new item). We'll be putting this
   functionality through its paces in the coming months.
-  The RSpec tests are lacking in some areas, so I will be adding to those over
   time as well. (Unfortunately, this gem was not developed with TDD best
   practices because it was lifted from PaperTrail and modified from there.)

This gem is inspired by the [Kentouzu][1] gem, which is based heavily on
[PaperTrail][2]. In fact, much of the structure for this gem emulates PaperTrail
(because it works beautifully). You should definitely check out PaperTrail and
its source: it's a nice clean example of a gem that hooks into Rails and
Sinatra.

## Features

-  Provides API for storing drafts of creations, updates, and destroys.
-  A max of one draft per record (via `belongs_to` association).
-  Does not store drafts for updates that don't change anything.
-  Allows you to specify attributes (by inclusion or exclusion) that must change
   for a draft to be stored.
-  Ability to query drafts based on the current drafted item, or query all
   drafts polymorphically on the `drafts` table.
-  `publish!` and `revert!` methods for drafts also handle any dependent drafts
   so you don't end up with orphaned records.
-  Allows you to get at every draft, even if the schema has since changed.
-  Automatically records who was responsible via your controller. Draftsman
   calls `current_user` by default if it exists, but you can have it call any
   method you like.
-  Allows you to store arbitrary model-level metadata with each draft (useful
   for filtering).
-  Allows you to store arbitrary controller-level information with each draft
   (e.g., remote IP, current account ID).
-  Only saves drafts when you explicitly tell it to via instance methods like
   `save_draft` and `draft_destruction`.
-  Stores everything in a single database table by default (generates migration
   for you), or you can use separate tables for separate models.
-  Supports custom draft classes so different models' drafts can have different
   behavior.
-  Supports custom name for `draft` association.
-  Supports `before`, `after`, and `around` callbacks on each draft persistence
   method, such as `before_save_draft` or `around_draft_destruction`.
-  Threadsafe.

## Compatibility

Compatible with ActiveRecord 4 and 5.

Works well with Rails, Sinatra, or any other application that depends on
ActiveRecord.

## Installation

### Rails 4 and 5

Add Draftsman to your `Gemfile`.

```ruby
gem 'draftsman', '~> 0.7.1'
```

Or if you want to grab the latest from `master`:

```ruby
gem 'draftsman', github: 'jmfederico/draftsman'
```

Generate a migration which will add a `drafts` table to your database.

    $ rails g draftsman:install

You can pass zero or any combination of these options to the generator:

    $ rails g draftsman:install --skip-initializer  # Skip generation of the boilerplate initializer at
                                                    # `config/initializers/draftsman.rb`.

    $ rails g draftsman:install --with-changes      # Store changeset (diff) with each draft.

    $ rails g draftsman:install --with-pg-json      # Use PostgreSQL JSON data type for serialized data.

Run the migration(s).

    $ rake db:migrate

Add `draft_id`, `published_at`, and `trashed_at` attributes to the models you
want to have drafts on. `trashed_at` is optional if you don't want to store
drafts for destroys.

    $ rails g migration add_drafts_to_widgets draft_id:integer published_at:timestamp trashed_at:timestamp
    $ rake db:migrate

Add `has_drafts` to the models you want to have drafts on.

Lastly, if your controllers have a `current_user` method, you can easily track
who is responsible for changes by adding a controller filter.

```ruby
class ApplicationController
  before_action :set_draftsman_whodunnit
end
```

### Sinatra

In order to configure Draftsman for usage with [Sinatra][5], your Sinatra app
must be using `ActiveRecord` 4 or greater. It is also recommended to use the
[Sinatra ActiveRecord Extension][6] or something similar for managing your
application's ActiveRecord connection in a manner similar to the way Rails does.
If using the aforementioned Sinatra ActiveRecord Extension, steps for setting up
your app with Draftsman will look something like this:

Add Draftsman to your `Gemfile`.

```ruby
gem 'draftsman', github: 'jmfederico/draftsman'
```

Generate a migration to add a `drafts` table to your database.

    $ rake db:create_migration NAME=create_drafts

Copy contents of [`create_drafts.rb`][7] into the `create_drafts` migration that
was generated into your `db/migrate` directory.

Run the migration(s).

    $ rake db:migrate

Add `draft_id`, `published_at`, and `trashed_at` attributes to the models you
want to have drafts on. (`trashed_at` is optional if you don't want to store
drafts for destroys.)

Add `has_drafts` to the models you want to have drafts on.

Draftsman provides a helper extension that acts similarly to the controller
mixin it provides for Rails applications.

It will set `Draftsman::Draft#whodunnit` to whatever is returned by a method
named `user_for_draftsman`, which you can define inside your Sinatra
application. (By default, it attempts to invoke a method named `current_user`.)

If you're using the modular [`Sinatra::Base`][8] style of application, you will
need to register the extension:

```ruby
# my_app.rb
require 'sinatra/base'

class MyApp < Sinatra::Base
  register Draftsman::Sinatra
end
```

## API Summary

### `has_draft` Options

To get started, add a call to `has_drafts` to your model. `has_drafts` accepts
the following options:

##### `:class_name`

The name of a custom `Draft` class. This class should inherit from
`Draftsman::Draft`. A global default can be set for this using
`Draftsman.draft_class_name=` if the default of `Draftsman::Draft` needs to be
overridden.

##### `:ignore`

An array of attributes for which an update to a `Draft` will not be stored if
they are the only ones changed.

##### `:only`

Inverse of `ignore` - a new `Draft` will be created only for these attributes if
supplied. It's recommended that you only specify optional attributes for this
(that can be empty).

##### `:skip`

Fields to ignore completely.  As with `ignore`, updates to these fields will not
create a new `Draft`. In addition, these fields will not be included in the
serialized versions of the object whenever a new `Draft` is created.

##### `:meta`

A hash of extra data to store.  You must add a column to the `drafts` table for
each key. Values are objects or `proc`s (which are called with `self`, i.e. the
model with the `has_drafts`). See `Draftsman::Controller.info_for_draftsman` for
an example of how to store data from the controller.

##### `:draft`

The name to use for the `draft` association shortcut method. Default is
`:draft`.

##### `:published_at`

The name to use for the method which returns the published timestamp. Default is
`published_at`.

##### `:trashed_at`

The name to use for the method which returns the soft delete timestamp. Default
is `trashed_at`.

##### `:publish_options`

The hash of options that will be passed to `#save` when publishing the draft.
Default is `{ valdiate: false }`

### Drafted Item Class Methods

When you install the Draftsman gem, you get these methods on each model class:

```ruby
# Returns whether or not `has_draft` has been called on the model.
Widget.draftable?

# Returns whether or not a `trashed_at` timestamp is set up on this model.
Widget.trashable?
```

### Drafted Item Instance Methods

When you call `has_drafts` in your model, you get the following methods. See the
"Basic Usage" section below for more context on where these methods fit into
your data's lifecycle.

```ruby
# Returns this widget's draft. You can customize the name of this association.
widget.draft

# Returns whether or not this widget has a draft.
widget.draft?

# Saves record and records a draft for the object's creation or update. Much
# like `ActiveRecord`'s `#save`, returns `true` or `false` depending on whether
# or not the objects passed validation and the save was successful.
widget.save_draft

# Trashes object and records a draft for a `destroy` event. (The `trashed_at`
# attribute must be set up on your model for this to work.)
widget.draft_destruction

# Returns whether or not this item has been published at any point in its
# lifecycle.
widget.published?

# Returns whether or not this item has been trashed via `#draft_destruction`.
widget.trashed?
```

### Drafted Item Scopes

You also get these scopes added to your model for your querying enjoyment:

```ruby
Widget.drafted    # Limits to items that have drafts. Best used in an "admin" area in your application.
Widget.published  # Limits to items that have been published at some point in their lifecycles. Best used in a "public" area in your application.
Widget.trashed    # Limits to items that have been drafted for deletion (but not fully committed for deletion). Best used in an "admin" area in your application.
Widget.live       # Limits to items that have not been drafted for deletion. Best used in an "admin" area in your application.
```

These scopes optionally take a `referenced_table_name` argument for constructing
more advanced queries using `.includes` eager loading or `.joins`. This reduces
ambiguity both for SQL queries and for your Ruby code.

```ruby
# Query live `widgets` and `gears` without ambiguity.
Widget.live.includes(:gears, :sprockets).live(:gears)
```

### Draft Class Methods

The `Draftsman::Draft` class has the following scopes:

```ruby
# Returns all drafts created by the `create` event.
Draftsman::Draft.creates

# Returns all drafts created by the `update` event.
Draftsman::Draft.updates

# Returns all drafts created by the `destroy` event.
Draftsman::Draft.destroys
```

### Draft Instance Methods

And a `Draftsman::Draft` instance has these methods:

```ruby
# Return the associated item in its state before the draft.
draft.item

# Return the object in its state held by the draft.
draft.reify

# Returns what changed in this draft. Similar to `ActiveModel::Dirty#changes`.
# Returns `nil` if your `drafts` table does not have an `object_changes` text
# column.
draft.changeset

# Returns whether or not this is a `create` event.
draft.create?

# Returns whether or not this is an `update` event.
draft.update?

# Returns whether or not this is a `destroy` event.
draft.destroy?

# Publishes this draft's associated `item`, publishes its `item`'s dependencies,
# and destroys itself.
# -  For `create` drafts, adds a value for the `published_at` timestamp on the
#    item and destroys the draft.
# -  For `update` drafts, applies the drafted changes to the item and destroys
#    the draft.
# -  For `destroy` drafts, destroys the item and the draft.
#
# Params:
# -  A hash of options that will be passed to item.save,
#    override publish_options defined with has_drafts.
draft.publish!

# Reverts this draft's associated `item` to its previous state, reverts its
# `item`'s dependencies, and destroys itself.
# -  For `create` drafts, destroys the draft and the item.
# -  For `update` drafts, destroys the draft only.
# -  For `destroy` drafts, destroys the draft and undoes the `trashed_at`
#    timestamp on the item. If a draft was drafted for destroy, restores the
#    draft.
draft.revert!

# Returns related draft dependencies that would be along for the ride for a
# `publish!` action.
draft.draft_publication_dependencies

# Returns related draft dependencies that would be along for the ride for a
# `revert!` action.
draft.draft_reversion_dependencies
```

### Callbacks

Draftsman supports callbacks for draft saves and destroys. These callbacks can
be defined in any model that `has_drafts`.

Draft callbacks work similarly to ActiveRecord callbacks; pass any functions
that you would like called before/around/after a draft persistence method.

Available callbacks:
```ruby
before_save_draft         # called before draft is saved
around_save_draft         # called function must yield to `save_draft`
after_draft_save          # called after draft is saved

before_draft_destruction  # called before item is destroyed as a draft
around_draft_destruction  # called function must yield to `draft_destruction`
after_draft_destruction   # called after item is destroyed as a draft
```

Note that callbacks must be defined after your call to `has_drafts`.

## Basic Usage

A basic `widgets` admin controller in Rails that saves all of the user's actions
as drafts would look something like this. It also presents all data in its
drafted form, if a draft exists.

```ruby
class Admin::WidgetsController < Admin::BaseController
  before_action :find_widget,  only: [:show, :edit, :update, :destroy]
  before_action :reify_widget, only: [:show, :edit]

  def index
    # The `live` scope gives us widgets that aren't in the trash.
    # It's also strongly recommended that you eagerly-load the `draft`
    # association via `includes` so you don't keep hitting your database for
    # each draft.
    @widgets = Widget.live.includes(:draft).order(:title)

    # Load drafted versions of each widget.
    @widgets.map! { |widget| widget.draft.reify if widget.draft? }
  end

  def show
  end

  def new
    @widget = Widget.new
  end

  def create
    @widget = Widget.new(widget_params)

    # Instead of calling `save`, you call `save_draft` to save it as a draft.
    if @widget.save_draft
      flash[:success] = 'Draft of widget saved successfully.'
      redirect_to [:admin, @widget]
    else
      flash[:error] = 'There was an error saving the draft.'
      render :new
    end
  end

  def edit
  end

  def update
    @widget.attributes = widget_params

    # Instead of calling `update`, you call `save_draft` to save it as a draft.
    if @widget.save_draft
      flash[:success] = 'Draft of widget saved successfully.'
      redirect_to [:admin, @widget]
    else
      flash[:error] = 'There was an error saving the draft.'
      render :edit
    end
  end

  def destroy
    # Instead of calling `destroy`, you call `draft_destruction` to "trash" it as a draft
    @widget.draft_destruction
    flash[:success] = 'The widget was moved to the trash.'
    redirect_to admin_widgets_path
  end

private

  # Finds non-trashed widget by `params[:id]`.
  def find_widget
    @widget = Widget.live.find(params[:id])
  end

  # If the widget has a draft, load that version of it.
  def reify_widget
    @widget = @widget.draft.reify if @widget.draft?
  end

  # Strong parameters for widget form.
  def widget_params
    params.require(:widget).permit(:title)
  end
end
```

And "public" controllers (let's say read-only for this simple example) would
ignore drafts entirely via the `published` scope. This also allows items to be
"trashed" for admins but still accessible to the public until that deletion is
committed.

```ruby
class WidgetsController < ApplicationController
  def index
    # The `published` scope gives us widgets that have been committed to be
    # viewed by non-admin users.
    @widgets = Widget.published.order(:title)
  end

  def show
    @widget = Widget.published.find(params[:id])
  end
end
```

Obviously, you can use the scopes that Draftsman provides however you would like
in any case.

Lastly, a `drafts` controller could be provided for admin users to see all
drafts, no matter the type of record (thanks to ActiveRecord's polymorphic
associations). From there, they could choose to revert or publish any draft
listed, or any other workflow action that you would like for your application to
provide for drafts.

```ruby
class Admin::DraftsController < Admin::BaseController
  before_action :find_draft, only: [:show, :update, :destroy]

  def index
    @drafts = Draftsman::Draft.includes(:item).order(updated_at: :desc)
  end

  def show
  end

  # Post draft ID here to publish it
  def update
    # Call `draft_publication_dependencies` to check if any other drafted
    # records should be published along with this `@draft`.
    @dependencies = @draft.draft_publication_dependencies

    # If you would like to warn the user about dependent drafts that would need
    # to be published along with this one, you would implement an
    # `app/views/drafts/update.html.erb` view template. In that view template,
    # you could list the `@dependencies` and show a button posting back to this
    # action with a name of `commit_publication`. (The button's being clicked
    # indicates to your application that the user accepts that the dependencies
    # should be published along with the `@draft`, thus avoiding orphaned
    # records).
    if @dependencies.empty? || params[:commit_publication]
      @draft.publish!
      flash[:success] = 'The draft was published successfully.'
      redirect_to [:admin, :drafts]
    else
      # Renders `app/views/drafts/update.html.erb`
    end
  end

  # Post draft ID here to revert it
  def destroy
    # Call `draft_reversion_dependencies` to check if any other drafted records
    # should be reverted along with this `@draft`.
    @dependencies = @draft.draft_reversion_dependencies

    # If you would like to warn the user about dependent drafts that would need
    # to be reverted along with this one, you would implement an
    # `app/views/drafts/destroy.html.erb` view template. In that view template,
    # you could list the `@dependencies` and show a button posting back to this
    # action with a name of `commit_reversion`. (The button's being clicked
    # indicates to your application that the user accepts that the dependencies
    # should be reverted along with the `@draft`, thus avoiding orphaned
    # records).
    if @dependencies.empty? || params[:commit_reversion]
      @draft.revert!
      flash[:success] = 'The draft was reverted successfully.'
      redirect_to [:admin, :drafts]
    else
      # Renders `app/views/drafts/destroy.html.erb`
    end
  end

private

  # Finds draft by `params[:id]`.
  def find_draft
    @draft = Draftsman::Draft.find(params[:id])
  end
end

```

If you would like your `Widget` to have callbacks, it might look something like this:

```ruby
class Widget < ActiveRecord::Base
  has_drafts

  before_save_draft :say_hi
  around_save_draft :surround_update

private

  def say_hi
    self.some_attr = 'Hi!'
  end

  def surround_update
    if self.persisted?
      # do something before update
      yield
      # do something after update
    else
      yield
    end
  end
end
```


## Differences from PaperTrail

If you are familiar with the PaperTrail gem, some parts of the Draftsman gem
will look very familiar.

However, there are some differences:

*  PaperTrail hooks into ActiveRecord callbacks so that versions can be saved
   automatically with your normal CRUD operations (`#save`, `#create`,
   `#update`, `#destroy`, etc.). Draftsman requires that you explicitly call its
   own CRUD methods in order to save a draft (`#save_draft` and
   `draft_destruction`).

*  PaperTrail's `Version#object` column looks "backward" and records the
   object's state _before_ the changes occurred. Because drafts record changes
   as they will look in the future, they must work differently. Draftsman's
   `Draft#object` records the object's state _after_ changes are applied to the
   master object. *But* `destroy` drafts record the object as it was _before_ it
   was destroyed (in case you want the option of reverting the destroy later and
   restoring the drafted item back to its original state).

## Semantic Versioning

Like many Ruby gems, Draftsman honors the concepts behind
[semantic versioning][10]:

> Given a version number MAJOR.MINOR.PATCH, increment the:
>
> 1.  MAJOR version when you make incompatible API changes,
> 2.  MINOR version when you add functionality in a backwards-compatible manner, and
> 3.  PATCH version when you make backwards-compatible bug fixes.

## Contributing

If you feel like you can add something useful to Draftsman, then don't hesitate
to contribute! To make sure your fix/feature has a high chance of being
included, please do the following:

1.  Fork the repo.

2.  Run `bundle install`.

3.  Run `RAILS_ENV=test bundle exec rake -f spec/dummy/Rakefile db:schema:load`
    to load test database schema.

4.  Add at least one test for your change. Only refactoring and documentation
    changes require no new tests. If you are adding functionality or fixing a
    bug, you need a test!

5.  Make all tests pass by running `rake`.

6.  Push to your fork and submit a pull request.

I can't guarantee that I will accept the change, but if I don't, I will be sure
to let you know why.

Here are some things that will increase the chance that your pull request is
accepted, taken straight from the Ruby on Rails guide:

-  Use Rails idioms
-  Include tests that fail without your code, and pass with it
-  Update the documentation, guides, or whatever is affected by your
   contribution

This gem is a work in progress. I am adding specs as I need features in my
application. Please add missing ones as you work on features or find bugs!

## License

Copyright 2013-2016 Minimal Orange, LLC.

Draftsman is released under the [MIT License][9].


[1]: https://github.com/seaneshbaugh/kentouzu
[2]: https://github.com/airblade/paper_trail
[4]: http://railscasts.com/episodes/416-form-objects
[5]: http://www.sinatrarb.com/
[6]: https://github.com/janko-m/sinatra-activerecord
[7]: https://raw.github.com/jmfederico/draftsman/master/lib/generators/draftsman/templates/create_drafts.rb
[8]: http://www.sinatrarb.com/intro.html#Modular%20vs.%20Classic%20Style
[9]: http://www.opensource.org/licenses/MIT
[10]: http://semver.org/
