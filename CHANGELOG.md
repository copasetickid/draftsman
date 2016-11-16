# CHANGELOG

## 0.6.0 - Release TBD

- [@chrisdpeters](https://github.com/chrisdpeters)
  [implemented](https://github.com/liveeditor/draftsman/commit/39e74ef34f34de83262761a383e94a7e7731d47f)
  [#53](https://github.com/liveeditor/draftsman/issues/53) -
  Add option to not stash drafted data separately
- [@chrisdpeters](https://github.com/chrisdpeters)
  [implemented](https://github.com/liveeditor/draftsman/commit/340e632b9590ae3a07f5b567df3ca2b6d9a5b804)
  [#31](https://github.com/liveeditor/draftsman/issues/51) -
  Allow `whodunnit` column name to be configurable
- [@chrisdpeters](https://github.com/chrisdpeters)
  [implemented](https://github.com/liveeditor/draftsman/commit/340e632b9590ae3a07f5b567df3ca2b6d9a5b804)
  [#51](https://github.com/liveeditor/draftsman/issues/51) -
  Performance: skip reification logic on create drafts
- [@chrisdpeters](https://github.com/chrisdpeters)
  [implemented](https://github.com/liveeditor/draftsman/commit/eae59a6991d9aef18a9f9a811ccc7a8668cd351f)
  [#47](https://github.com/liveeditor/draftsman/issues/47) -
  Add ``#save_draft` method to classes initialized with ``#has_drafts`
- [@chrisdpeters](https://github.com/chrisdpeters)
  [fixed](https://github.com/liveeditor/draftsman/commit/696caf78baff938ebdf98c2867f6c4d2610b4611)
  [#49](https://github.com/liveeditor/draftsman/issues/49) -
  irb: warn: can't alias context from irb_context

## 0.5.1 - August 20, 2016

- [@chrisdpeters](https://github.com/chrisdpeters)
  [Fixed](https://github.com/liveeditor/draftsman/commit/b19efe6abf73b2e62a420df2aef39dc9eabf20dc)
  Make Draftsman enabled in Rails by default

## 0.5.0 - August 20, 2016

- [@npezza93](https://github.com/npezza93)
  [Implemented](https://github.com/liveeditor/draftsman/pull/45)
  [#44](https://github.com/liveeditor/draftsman/issues/44)
  Rails 5 compatibility

## 0.4.0 - April 5, 2016

- [@npafundi](https://github.com/npafundi)
  [Implemented](https://github.com/liveeditor/draftsman/pull/20)
  [#20](https://github.com/liveeditor/draftsman/pull/20) -
  Adding callbacks for draft creation, update, and destroy
- [@chrisdpeters](https://github.com/chrisdpeters)
  [Implemented](https://github.com/liveeditor/draftsman/commit/b3cecfa17f5cf296e7451cca56aeee41eac75f11)
  [#16](https://github.com/liveeditor/draftsman/issues/16) -
  Rename `draft_destroy` to `draft_destruction`
- [@defbyte](https://github.com/defbyte)
  [Fixed](https://github.com/liveeditor/draftsman/pull/38)
  [#39](https://github.com/liveeditor/draftsman/issues/39) -
  Uh oh, ActiveSupport::DeprecationException error when running generated migrations
- [@chrisdpeters](https://github.com/chrisdpeters)
  [Fixed](https://github.com/liveeditor/draftsman/commit/b0e328276e1e90ab877a6003f1d3165c7032267d)
  [#40](https://github.com/liveeditor/draftsman/issues/40) -
  Docs say publish! is available on the model instance, but it is not
- [@chrisdpeters](https://github.com/chrisdpeters)
  [Fixed](https://github.com/liveeditor/draftsman/commit/bae427d2d38715da5b892888ff86d23bf5e39cb0)
  [#17](https://github.com/liveeditor/draftsman/issues/17) -
  Fix "open-ended dependency on rake" warning on gem build

## 0.3.7 - November 4, 2015

- [@bdunham](https://github.com/bdunham)
  [Fixed](https://github.com/liveeditor/draftsman/commit/3610087a319fd203684146bb1d37bf0e41276743) -
  Prevented double require of model definition
- [@chrisdpeters](https://github.com/chrisdpeters)
  [Fixed](https://github.com/liveeditor/draftsman/commit/ec2edf45700a3bea8cfac6f9facbc8ef6c7f9f54)
  [#36](https://github.com/liveeditor/draftsman/issues/36) -
  Fails miserably with foreign keys
- [@dpaluy](https://github.com/dpaluy)
  [Fixed](https://github.com/dpaluy/draftsman/blob/afce35b3985c79760176f31710c11a77b1201f0e/config/initializers/draftsman.rb)
  [#33](https://github.com/liveeditor/draftsman/issues/33) -
  SerializedAttributes is deprecated in Rails 4.2.x, and will be removed in Rails 5
- [@chrisdpeters](https://github.com/chrisdpeters)
  [Fixed](https://github.com/liveeditor/draftsman/commit/adc2843105e8fcf34d714557e82cf3f24942dbcb) -
  Fix `serve_static_assets` deprecation warning

## 0.3.6 - August 16, 2015

- [@chrisdpeters](https://github.com/chrisdpeters)
  [Fixed](https://github.com/liveeditor/draftsman/commit/971b3d945e9190fbb103acac09c9d006db7a2a31) -
  Fix loading of Rails controller module for Rails 4.2+

## 0.3.5 - July 12, 2015

- [@npafundi](https://github.com/npafundi)
  [Fixed](https://github.com/liveeditor/draftsman/pull/29)
  [#28](https://github.com/liveeditor/draftsman/issues/28) -
  Skipped attributes aren't updated if a model has a draft

## 0.3.4 - May 21, 2015

- [@npafundi](https://github.com/npafundi)
  [Fixed](https://github.com/liveeditor/draftsman/pull/21)
  [#13](https://github.com/liveeditor/draftsman/issues/13) -
  LoadError when trying to run migrations
- [@npafundi](https://github.com/npafundi)
  [Fixed](https://github.com/liveeditor/draftsman/pull/23)
  [#22](https://github.com/liveeditor/draftsman/issues/22) -
  Exception on draft_destroy when has_one association is nil
- [@chrisdpeters](https://github.com/chrisdpeters)
  [Fixed](https://github.com/liveeditor/draftsman/commit/32b13375f4e50bafc3b4516d731d2fcf51a5fb2b)
  [#24](https://github.com/liveeditor/draftsman/issues/24) -
  Stack too deep: Error when running `bundle exec rails c` in app including draftsman

## 0.3.3 - April 8, 2015

-  Fixed regression [#18](https://github.com/liveeditor/draftsman/pull/19) - Exception when destroying drafts

## 0.3.2 - April 6, 2015

-  Fixed [#8](https://github.com/liveeditor/draftsman/issues/8) - Update specs to use new community standards
-  Fixed [#9](https://github.com/liveeditor/draftsman/issues/9) - Sinatra extension should not use Sinatra base namespace
-  Fixed [#12](https://github.com/liveeditor/draftsman/issues/12) - JSON::ParserError when draft_destroying a widget which was just created

## 0.3.1 - August 14, 2014

-  Commit [aae737f](https://github.com/live-editor/draftsman/commit/aae737fcdf48604bc480b1c9c141bf642c0f581c) - `skip` option not persisting skipped values correctly

## 0.3.0 - July 29, 2014

-  Commit [1e2a59f](https://github.com/live-editor/draftsman/commit/1e2a59f678cc4d88222dfc1976d564b5649cd329) - Add support for PostgreSQL JSON data type for `object`, `object_changes`, and `previous_draft` columns.

## v0.2.1 - June 28, 2014

-  Commit [dbc6c83](https://github.com/live-editor/draftsman/commit/dbc6c83abbea5211f67ad883f4a2d18a9f5ac181) - Reifying a record that was drafted for destruction uses data from a drafted update before that if that's what happened.

## v0.2.0 - June 3, 2014

-  Fixed [#4](https://github.com/live-editor/draftsman/issues/4) - Added `referenced_table_name` argument to scopes.

## v0.1.1 - March 7, 2014

-  Fixed [#3](https://github.com/minimalorange/draftsman/issues/3) - draft_publication_dependencies not honoring drafts
   when draft is an update.
-  Fixed [#1](https://github.com/minimalorange/draftsman/issues/1) - License missing from gemspec - Added MIT license.

## v0.1.0 - November 19, 2013

-  Initial release.
