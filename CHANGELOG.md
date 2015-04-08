# CHANGELOG

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
