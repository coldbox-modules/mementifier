# Mementifier

Welcome to the `mementifier` module.  This module will listen to traditional ORM events and inject some transformation goodness to your objects.

## Usage

The memementifier will listen to orm new and load operations.  Once it detects an entity and if contains a `this.memento` definition, it will inject a `getMemento()` method into the entity.  This method will allow you to transform the entity and its relationship into native struct/array/native formats instead of the object graph.  

### `this.memento` Marker

Each entity must be marked with a `this.memento` struct with the following available keys:

```js
this.mememento = {
	// An array of the properties/relationships to include by default
	defaultIncludes = [],
	// An array of properties/relationships to exclude by default
	defaultExcludes = [],
	// An array of properties/relationships to NEVER include
	neverInclude = [],
	// A struct of defaults for properties/relationships if they are null
	defaults = {},
	// A struct of mapping functions for properties/relationships that can transform them
	mappers = {}
}
```

## Settings

Just open your `config/Coldbox.cfc` and add the following settings into the `moduleSettings` struct under the `mementifier` key:

```js
// module settings - stored in modules.name.settings
moduleSettings = {
	mementifier = {
		// Turn on to use the ISO8601 date/time formatting on all processed date/time properites, else use the masks
		iso8601Format = false,
		// The default date mask to use for date properties
		dateMask      = "yyyy-mm-dd",
		// The default time mask to use for date properties
		timeMask      = "HH:mm:ss"
	}
}
```

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
