# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

----

## [3.3.1] => 2023-MAR-20

### Fixed

* `autoCastBooleans` on `getMemento()` was always set to `true`.

----

## [3.3.0] => 2023-MAR-17

### Added

* New global settings `autoCastBooleans` which allows you to turn this feature on or off.  By default we inspect if a value is not numeric and `isBoolean` and auto cast it to Java `Boolean` so it translated to a boolean in json.
* New `this.memento.autoCastBooleans` so you can turn on/off this feature at an entity level.
* New `autoCastBooleans` argument to the `getMemento()` to turn on/off this feature for that call only.

----

## [3.2.0] => 2023-JAN-19

### Fixed

* Issue occurs where the `iso8601Format` flag is only being applied to the top level object properties and does not cascade, resulting in child date properties not being properly formatted. https://github.com/coldbox-modules/mementifier/pull/33
* `datemask` and `timeMask` arguments where not being params by default
* `gh-release` action had the wrong code

### Improvements

* Updated all the GHA actions to newest levels and compatible Java builds.

----

## [3.1.0] => 2022-NOV-10

### Added

* Refactored the ORM includes to its own function
* ORM Includes is only set to `true` if `cborm` has been registered

----

## [3.0.1] => 2022-OCT-18

### Fixed

* fix: Use `box:` namespace for CommandBox compatibility

----


## [3.0.0] => 2022-SEP-22

### Added

* New github action workflows
* New module template files
* Faster approach to dealing with loading and processing of entities by eager loading Java classes that are used always

### Fixed

* Prevent argument modification and duplicate includes processing: https://github.com/coldbox-modules/mementifier/pull/26

### Changed

* Dropped ACF2016

----

## [2.8.0] => 2022-JAN-11

### Added

* Migration to github actions
* CFFormatting Rules

### Fixed

* Composite keys and no default includes fails (https://github.com/coldbox-modules/mementifier/pull/24)
* Fix mappers for keys not in memento (https://github.com/coldbox-modules/mementifier/pull/23)

----

## [2.7.0] => 2021-JUN-07

### Added

* New mementifier `profiles`. You can now create multiple output profiles in your `this.memento.profiles` which can be used to mementify your object graph.

----

## [2.6.0] => 2021-MAY-12

### Added

* New setting `convertToTimezone` which if you set a timezone, mementifier will convert date/time's to that specific timezone.

----

## [2.5.0] => 2021-APR-30

### Added

* Ability to do output aliases using `:` notation: `property:alias`

### Fixed

* When using orm with composite keys and no default includes it should look at the metdata for the identifier type not the includes


----

## [2.4.0] => 2021-MAR-22

### Added

* ColdBox 6 Testing upgrades
* cborm 3 testing
* TestBox 4 upgrade
* Full varscoping access to avoid scope lookups
* Markdown linting
* Updated formatting rules
* Updated travis OS

### Fixed

* fix: Correctly apply nested mappers [#20](https://github.com/coldbox-modules/mementifier/pull/20)

----

## [2.3.0] => 2020-NOV-17

### Added

* Thanks to @elpete you can now add date/time formatting rules at the `getmemento()` level and the `this.memento` level. Please see the [readme](readme.md) for further information.

----

## [2.2.1] => 2020-NOV-06

### Fixed

* Reverted missing `nestedIncludes.len()` for ignore defaults on nested hierarchies.

----

## [2.2.0] => 2020-NOV-05

### Added

* Allow defaults to be `null` thanks to @elpete
* Updated changelog to new keepachangelog.com standards
* Added new release recipe according to new module template
* Added new formating rules
* Added github auto publishing on releases

----

## [2.1.0] => 2020-MAR-10

* `Feature` : Enabled mappers to be called after memento was finalized in order to allow you to build composite properties and non-existent properties on the memento
* `Feature` : New setting `trustedGetters` to allow you to leverage virtual `getters()` especially on frameworks like Quick. This setting can also be used in the `getMemento()` calls directly or setup in an entity definition.

----

## [2.0.0] => 2020-JAN-22

### Features

* Enabled wildcard default includes (*) to retrieve inherited object properties instead of doing wacky things for inherited defaults to work.
* New setting to chose a default value to expose when getters return `null`: `nullDefaultValue`
* ORM Auto includes now ONLY includes properties to avoid bi-directional recursive exceptions.  This is also a compatiblity, where before EVERYTHING was included.  Now, only properties are included.

### Improvements

* Updated to cborm2 for testing harness
* Updated to TestBox 3

### Compatibility

* Removed ACF 11 Support
* ORM Auto includes only marshalls properties instead of everything.

----

## [1.9.0]

* More Adobe ColdFusion incompatibilities

----

## [1.8.0]

* Added the `ResultsMapper` model which will create results map a-la cffractal.  Just inject and call via the `process()` method.

----

## [1.7.1]

* ACF11 Compats

----

## [1.7.0]

* Allow for `defaultIncludes = [ "*" ]` to introspect the properties of the object automatically instead of writing all properties manually.

----

## [1.6.0]

* Allow for arrays of complex objects that don't have mementos
* ACF11 Incompats due to member functions

----

## [1.5.0]

* Only process memento based objects from WireBox.

----

## [1.4.1]

* Wrong date formatting pattern for Java SimpleDateFormat

----

## [1.4.0]

* New setting: `ormAutoIncludes` which defaults to `true`.  If enabled, and an ORM entity does not have any includes defined, we will automatically include all ORM properties including relationships.

----

## [1.3.0]

* ACF Incompatibilities
* Ensure result item

----

## [1.1.1]

* Fixes on non-existent properties

----

## [1.1.0]

* Major performance boosts
* Lucee issues with degradation over time

----

## [1.0.1]

* Fix on WireBox target detection

----

## [1.0.0]

* First iteration of this module
