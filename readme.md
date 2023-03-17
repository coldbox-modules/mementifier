# Mementifier : The State Maker!

Welcome to the `mementifier` module.  This module will transform your business objects into native ColdFusion (CFML) data structures with :rocket: speed.  It will inject itself into ORM objects and/or business objects alike and give them a nice `getMemento()` function to transform their properties and relationships (state) into a consumable structure or array of structures.  It can even detect ORM entities and you don't even have to write the default includes manually, it will auto-detect all properties.  No more building transformations by hand! No more inconsistencies! No more repeating yourself!

> Memento pattern is used to restore state of an object to a previous state or to produce the state of the object.

You can combine this module with `cffractal` (https://forgebox.io/view/cffractal) and build consistent and fast :rocket: object graph transformations.

## Module Settings

Just open your `config/Coldbox.cfc` and add the following settings into the `moduleSettings` struct under the `mementifier` key or create a new `config/modules/mementifier.cfc` in ColdBox 7:

```js
// module settings - stored in modules.name.settings
moduleSettings = {
	mementifier = {
		// Turn on to use the ISO8601 date/time formatting on all processed date/time properites, else use the masks
		iso8601Format = false,
		// The default date mask to use for date properties
		dateMask      = "yyyy-MM-dd",
		// The default time mask to use for date properties
		timeMask      = "HH:mm:ss",
		// Enable orm auto default includes: If true and an object doesn't have any `memento` struct defined
		// this module will create it with all properties and relationships it can find for the target entity
		// leveraging the cborm module.
		ormAutoIncludes = true,
		// The default value for relationships/getters which return null
		nullDefaultValue = '',
        // Don't check for getters before invoking them
        trustedGetters = false,
		// If not empty, convert all date/times to the specific timezone
		convertToTimezone = "",
		// Verifies if values are not numeric and isBoolean() and do auto casting to Java Boolean
		autoCastBooleans : true
	}
}
```

## Usage

The memementifier will listen to WireBox object creations and ORM events in order to inject itself into target objects.  The target object must contain a `this.memento` structure in order for the `mementifier` to inject a `getMemento()` method into the target.  This method will allow you to transform the entity and its relationships into native struct/array/native formats.

### `this.memento` Marker

Each entity must be marked with a `this.memento` struct with the following (optional) available keys:

```js
this.memento = {
	// An array of the properties/relationships to include by default
	defaultIncludes = [],
	// An array of properties/relationships to exclude by default
	defaultExcludes = [],
	// An array of properties/relationships to NEVER include
	neverInclude = [],
	// A struct of defaults for properties/relationships if they are null
	defaults = {},
	// A struct of mapping functions for properties/relationships that can transform them
    mappers = {},
    // Don't check for getters before invoking them
    trustedGetters = $mementifierSettings.trustedGetters,
    // Enable orm auto default includes
    ormAutoIncludes = $mementifierSettings.ormAutoIncludes,
    // Use the ISO 8601 formatter for this component
    iso8601Format = $mementifierSettings.iso8601Format,
    // Use a custom date mask for this component
    dateMask = $mementifierSettings.dateMask,
	// Use a custom time mask for this component
    timeMask = $mementifierSettings.timeMask,
	// A collection of mementifier profiles you can use to create many output permutations
	profiles = {
		name = {
			defaultIncludes : [],
			defaultExcludes : [],
			neverInclude = [],
			defaults = {},
			mappers = {}
			...
		}
	},
	// Auto cast boolean strings to Java boolean
	autoCastBooleans = true
}
```

#### Default Includes

This array is a collection of the properties and/or relationships to add to the resulting memento of the object by default.  The `mementifier` will call the public `getter` method for the property to retrieve its value. If the returning value is `null` then the value will be an `empty` string.  If you are using CF ORM and the `ormAutoIncludes` setting is **true** (by default), then this array can be auto-populated for you, no need to list all the properties.

```js
defaultIncludes = [
	"firstName",
	"lastName",
	// Relationships
	"role.roleName",
	"role.roleID",
	"permissions",
	"children"
]
```

##### Automatic Include Properties

You can also create a single item of `[ "*" ]` which will tell the mementifier to introspect the object for all `properties` and use those instead for the default includes.

```java
defaultIncludes = [ "*" ]
```

> Also note the `ormAutoIncludes` setting, which if you are using a ColdFusion ORM object, we will automatically add all properties to the default includes.

##### Custom Includes

You can also define here properties that are NOT part of the object graph, but determined/constructed at runtime.  Let's say your `User` object needs to have an `avatarLink` in it's memento.  Then you can add a `avatarLink` to the array and create the appropriate `getAvatarLink()` method.  Then the `mementifier` will call your getter and add it to the resulting memento.

```js
defaultIncludes = [
	"firstName",
	"lastName",
	"avatarLink"
]

/**
* Get the avatar link for this user.
*/
string function getAvatarLink( numeric size=40 ){
	return variables.avatar.generateLink( getEmail(), arguments.size );
}
```
##### Includes Aliasing

You may also wish to alias properties or getters in your components to a different name in the generated memento.  You may do this by using a colon with the left hand side as the name of the property or getter ( without the `get` ) and the right hand side as the alias. For example let's say we had a getter of `getLastLoginTime` but we wanted to reference it as `lastLogin` in the memento.  We can do this with aliasing.

```js
defaultIncludes = [
	"firstName",
	"lastName",
	"avatarLink",
	"lastLoginTime:lastLogin"
]
```

##### Nested Includes

The `DefaultIncldues` array can also include **nested** relationships.  So if a `User` has a `Role` relationship and you want to include only the `roleName` property, you can do `role.roleName`.  Every nesting is demarcated with a period (`.`) and you will navigate to the relationship.

```js
defaultIncludes = [
	"firstName",
	"lastName",
	"role.roleName",
	"role.roleID",
	"permissions"
]
```

Please note that all nested relationships will ONLY bring those properties from the relationship. Not the entire relationship.

#### Default Excludes

This array is a declaration of all properties/relationships to exclude from the memento state process.

```js
defaultExcludes = [
	"APIToken",
	"userID",
	"permissions"
]
```

##### Nested Excludes

The `DefaultExcludes` array can also declare **nested** relationships.  So if a `User` has a `Role` relationship and you want to exclude the `roleID` property, you can do `role.roleId`.  Every nesting is demarcated with a period (`.`) and you will navigate to the relationship and define what portions of the nested relationship can be excluded out.

```js
defaultExcludes = [
	"role.roleID",
	"permissions"
]
```

#### Never Include

This array is used as a last line of defense.  Even if the `getMemento()` call receives an include that is listed in this array, it will still not add it to the resulting memento.  This is great if you are using dynamic include and exclude lists.  **You can also use nested relationships here as well.**

```js
neverInclude = [
	"password"
]
```

#### Defaults

This structure will hold the default values to use for properties and/or relationships if at runtime they have a `null` value.  The `key` of the structure is the name of the property and/or relationship.  Please note that if you have a collection of relationships (array), the default value is an empty array by default.  This mostly applies if you want complete control of the default value.

```js
defaults = {
	"role" : {},
	"office" : {}
}
```

#### Mappers

This structure is a way to do transformations on actual properties and/or relationships after they have been added to the memento.  This can be post-processing functions that can be applied after retrieval. The `key` of the structure is the name of the property and/or relationship.  The `value` is a closure that receives the item and the rest of the memento and it must return back the item mapped according to your function.

```js
mappers = {
	"lname" = function( item, memento ){ return item.ucase(); },
	"specialDate" = function( item, memento ){ return dateTimeFormat( item, "full" ); }
}
```

You can use mappers to include a key not found in your memento, but rather one that combines values from other values.

```js
mappers = {
    "fullname" = function( _, memento ) { return memento.fname & " " & memento.lname; }
}
```

### `getMemento()` Method

Now that you have learned how to define what will be created in your memento, let's discover how to actually get the memento.  The injected method to the business objects has the following signaure:

```js
struct function getMemento(
	includes="",
	excludes="",
	struct mappers={},
	struct defaults={},
    boolean ignoreDefaults=false,
	boolean trustedGetters,
	boolean iso8601Format,
	string dateMask,
	string timeMask,
	string profile = "",
	boolean autoCastBooleans = true
)
```

> You can find the API Docs Here: https://apidocs.ortussolutions.com/coldbox-modules/mementifier/1.0.0/index.html

As you can see, the memento method has also a way to add dynamic `includes`, `excludes`, `mappers` and `defaults`.  This will allow you to add upon the defaults dynamically.

#### Ignoring Defaults

We have also added a way to ignore the default include and exclude lists via the `ignoreDefaults` flag.  If you turn that flag to `true` then **ONLY** the passed in `includes` and `excludes` will be used in the memento.  However, please note that the `neverInclude` array will **always** be used.

#### Output Profiles

You can use the `this.memento.profiles` to define many output profiles a part from the defaults includes and excludes.  This is used by using the `profile` argument to the `getMemento()` call.  The mementifier will then pass in the profile argument to the object and it's entire object graph.  If a child of the object graph does NOT have that profile, it will rever to the defaults instead.

This is a great way to encapsulate many different output mementifiying options:

```
// Declare your profiles
this.memento = {
	defaultIncludes : [
		"allowComments",
		"cache",
		"cacheLastAccessTimeout",
		"cacheLayout",
		"cacheTimeout",
		"categoriesArray:categories",
		"contentID",
		"contentType",
		"createdDate",
		"creatorSnapshot:creator", // Creator
		"expireDate",
		"featuredImage",
		"featuredImageURL",
		"HTMLDescription",
		"HTMLKeywords",
		"HTMLTitle",
		"isPublished",
		"isDeleted",
		"lastEditorSnapshot:lastEditor",
		"markup",
		"modifiedDate",
		"numberOfChildren",
		"numberOfComments",
		"numberOfHits",
		"numberOfVersions",
		"parentSnapshot:parent", // Parent
		"publishedDate",
		"showInSearch",
		"slug",
		"title"
	],
	defaultExcludes : [
		"children",
		"comments",
		"commentSubscriptions",
		"contentVersions",
		"customFields",
		"linkedContent",
		"parent",
		"relatedContent",
		"site",
		"stats"
	],
	neverInclude : [ "passwordProtection" ],
	mappers      : {},
	defaults     : { stats : {} },
	profiles     : {
		export : {
			defaultIncludes : [
				"children",
				"comments",
				"commentSubscriptions",
				"contentVersions",
				"customFields",
				"linkedContent",
				"relatedContent",
				"siteID",
				"stats"
			],
			defaultExcludes : [
				"commentSubscriptions.relatedContentSnapshot:relatedContent",
				"children.parentSnapshot:parent",
				"parent",
				"site"
			]
		}
	}
};
// Incorporate all defaults into export profile to avoid duplicate writing them
this.memento.profiles[ "export" ].defaultIncludes.append( this.memento.defaultIncludes, true );
```

Then use it via the `getMemento()` method call:

```
content.getMemento( profile: "export" )
```

Please note that you can still influence the profile by passing in extra `includes`, `excludes` and all the valid memento arguments.


#### Trusted Getters

You can turn on trusted getters during call time by passing `true` to the `trustedGetters` argument.

#### Overriding `getMemento()`

You might be in a situation where you still want to add custom magic to your memento and you will want to override the injected `getMemento()` method.  No problem!  If you create your own `getMemento()` method, then the `mementifier` will inject the method as `$getMemento()`  so you can do your overrides:

```js
struct function getMemento(
	includes="",
	excludes="",
	struct mappers={},
	struct defaults={},
	boolean ignoreDefaults=false,
	boolean trustedGetters,
	boolean iso8601Format,
	string dateMask,
	string timeMask,
	string profile = "",
	boolean autoCastBooleans = true
){
	// Call mementifier
	var memento	= this.$getMemento( argumentCollection=arguments );

	// Add custom data
	if( hasEntryType() ){
		memento[ "typeSlug" ] = getEntryType().getTypeSlug();
		memento[ "typeName" ] = getEntryType().getTypeName();
	}

	return memento;
}
```

## Timezone Conversions

Mementifier can also convert date/time objects into specific formats but also a specific timezone. You will use the `convertToTimezone` configuration setting and set it to a valid Java Timezone string.  This can be either an abbreviation such as "PST", a full name such as "America/Los_Angeles", or a custom ID such as "GMT-8:00". Nice listing: https://garygregory.wordpress.com/2013/06/18/what-are-the-java-timezone-ids/

```
convertToTimezone : "UTC"
```

That's it. Now mementifier will format the date/times with the appropriate selected timezone or use the system default timezone.

## Results Mapper

This feature was created to assist in support of the cffractal results map format.  It will process an array of objects and create a returning structure with the following specification:

* `results` - An array containing all the unique identifiers from the array of objects processed
* `resultsMap` - A struct keyed by the unique identifier containing the memento of each of those objects.

Example:

```js
// becomes
var data = {
    "results" = [
        "F29958B1-5A2B-4785-BE0A11297D0B5373",
        "42A6EB0A-1196-4A76-8B9BE67422A54B26"
    ],
    "resultsMap" = {
        "F29958B1-5A2B-4785-BE0A11297D0B5373" = {
            "id" = "F29958B1-5A2B-4785-BE0A11297D0B5373",
            "name" = "foo"
        },
        "42A6EB0A-1196-4A76-8B9BE67422A54B26" = {
            "id" = "42A6EB0A-1196-4A76-8B9BE67422A54B26",
            "name" = "bar"
        }
    }
};
```

Just inject the results mapper using this WireBox ID: `ResultsMapper@mementifier` and call the `process()` method with your collection, the unique identifier key name (defaults to `id`) and the other arguments that `getMemento()` can use. Here is the signature of the method:

```js
/**
 * Construct a memento representation using a results map. This process will iterate over the collection and create a
 * results array with all the identifiers and a struct keyed by identifier of the mememnto data.
 *
 * @collection The target collection
 * @id The identifier key, defaults to `id` for simplicity.
 * @includes The properties array or list to build the memento with alongside the default includes
 * @excludes The properties array or list to exclude from the memento alongside the default excludes
 * @mappers A struct of key-function pairs that will map properties to closures/lambadas to process the item value.  The closure will transform the item value.
 * @defaults A struct of key-value pairs that denotes the default values for properties if they are null, defaults for everything are a blank string.
 * @ignoreDefaults If set to true, default includes and excludes will be ignored and only the incoming `includes` and `excludes` list will be used.
 *
 * @return struct of { results = [], resultsMap = {} }
 */
function process(
	required array collection,
	id="id",
	includes="",
	excludes="",
	struct mappers={},
	struct defaults={},
    boolean ignoreDefaults=false,
    boolean trustedGetters
){}
```

## Auto Cast Booleans

By default, mementifier will evaluate if the incoming value is not numeric and `isBoolean()` and if so, convert it to a Java `Boolean` so when marshalled it will be a `true` or `false=` in the output json.  However we understand this can be annoying or too broad of a stroke, so you can optionally disable it in different levels:

1. Global Setting
1. Entity Level
1. `getMemento()` Level

### Global Setting

You can set the `autoCastBooleans` global setting in the mementifier settings.

### Entity Level

You can set the `autoCastBooleans` property in the `this.memento` struct.

### `getMemento()` Level

You can pass in the `autoCastBooleans` argument to the `getMemento()` and use that as the default.


********************************************************************************
Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.ortussolutions.com
********************************************************************************
#### HONOR GOES TO GOD ABOVE ALL
Because of His grace, this project exists. If you don't like this, then don't read it, its not for you.

>"Therefore being justified by faith, we have peace with God through our Lord Jesus Christ:
By whom also we have access by faith into this grace wherein we stand, and rejoice in hope of the glory of God.
And not only so, but we glory in tribulations also: knowing that tribulation worketh patience;
And patience, experience; and experience, hope:
And hope maketh not ashamed; because the love of God is shed abroad in our hearts by the
Holy Ghost which is given unto us. ." Romans 5:5

### THE DAILY BREAD
 > "I am the way, and the truth, and the life; no one comes to the Father, but by me (JESUS)" Jn 14:1-12
