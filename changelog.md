# Changelog

## v1.9.0

* More Adobe ColdFusion incompatibilities

## v1.8.0

* Added the `ResultsMapper` model which will create results map a-la cffractal.  Just inject and call via the `process()` method.

## v1.7.1

* ACF11 Compats

## v1.7.0

* Allow for `defaultIncludes = [ "*" ]` to introspect the properties of the object automatically instead of writing all properties manually.

## v1.6.0

* Allow for arrays of complex objects that don't have mementos
* ACF11 Incompats due to member functions

## v1.5.0

* Only process memento based objects from WireBox.

## v1.4.1

* Wrong date formatting pattern for Java SimpleDateFormat

## v1.4.0

* New setting: `ormAutoIncludes` which defaults to `true`.  If enabled, and an ORM entity does not have any includes defined, we will automatically include all ORM properties including relationships.

## v1.3.0

* ACF Incompatibilities
* Ensure result item

## v1.1.1

* Fixes on non-existent properties

## v1.1.0

* Major performance boosts
* Lucee issues with degradation over time

## v1.0.1

* Fix on WireBox target detection

## v1.0.0

* First iteration of this module