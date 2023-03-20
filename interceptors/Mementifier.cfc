/**
 * Listen to various entity methods so we can inject our mementifying capabilties to objects.
 * If an object already has a `getMemento()` method, we will inject a `$getMemento()` method so you can still decorate it.
 */
component {

	// DI
	property name="settings" inject="box:moduleSettings:mementifier";

	/**
	 * Configure interceptor
	 */
	function configure(){
		variables.jTimezone         = createObject( "java", "java.util.TimeZone" );
		variables.jSimpleDateFormat = createObject( "java", "java.text.SimpleDateFormat" );
		variables.jArrays           = createObject( "java", "java.util.Arrays" );
	}

	/*********************************** WIREBOX EVENTS ***********************************/

	/**
	 * Listen to object creations and attach ourselves into them
	 */
	function afterInstanceCreation( interceptData ){
		// Only process struct based objects with the `memento` property
		if (
			isStruct( arguments.interceptData.target ) && structKeyExists(
				arguments.interceptData.target,
				"memento"
			)
		) {
			processMemento( arguments.interceptData.target );
		}
	}

	/*********************************** CBORM EVENTS ***********************************/

	/**
	 * Listen to entity creations
	 *
	 * @interceptData
	 */
	function ORMPostNew( interceptData ){
		processMemento( arguments.interceptData.entity );
	}

	/**
	 * Listen to entity loads
	 *
	 * @interceptData
	 */
	function ORMPostLoad( interceptData ){
		processMemento( arguments.interceptData.entity );
	}

	/*********************************** PROCESSOR ***********************************/

	/**
	 * Process the memento decorations
	 *
	 * @entity The entity to process
	 */
	function processMemento( entity ){
		// Verify we haven't mementified this object already
		if ( !structKeyExists( arguments.entity, "$mementifierSettings" ) ) {
			// systemOutput( "==> Injectin mementifier: #getMetadata( arguments.entity ).name# ", true );

			// Inject utility
			arguments.entity.$injectMixin = variables.$injectMixin;
			// Inject Settings
			arguments.entity.$injectMixin( "$mementifierSettings", variables.settings );

			// Inject getMemento if not overriden
			if ( !structKeyExists( arguments.entity, "getMemento" ) ) {
				arguments.entity.$injectMixin( "getMemento", variables.getMemento );
			}
			// Else inject it with the $getMemento alias
			else {
				arguments.entity.$injectMixin( "$getMemento", variables.getMemento );
			}

			// Inject helper methods
			arguments.entity.$injectMixin( "$buildOrmIncludes", variables.$buildOrmIncludes );
			arguments.entity.$injectMixin( "$buildNestedMementoList", variables.$buildNestedMementoList );
			arguments.entity.$injectMixin( "$buildNestedMementoStruct", variables.$buildNestedMementoStruct );
			arguments.entity.$injectMixin( "$getDeepProperties", variables.$getDeepProperties );

			// We do simple date formatters as they are faster than CFML methods
			var dateMask                        = isNull( this.memento.dateMask ) ? variables.settings.dateMask : this.memento.dateMask;
			var timeMask                        = isNull( this.memento.timeMask ) ? variables.settings.timeMask : this.memento.timeMask;
			arguments.entity.$FORMATTER_ISO8601 = variables.jSimpleDateFormat.init( "yyyy-MM-dd'T'HH:mm:ssXXX" );
			arguments.entity.$FORMATTER_CUSTOM  = variables.jSimpleDateFormat.init( "#dateMask# #timeMask#" );

			// Do we set timezones?
			if ( len( variables.settings.convertToTimezone ) ) {
				var tz = variables.jTimezone.getTimeZone( variables.settings.convertToTimezone );
				arguments.entity.$FORMATTER_ISO8601.setTimezone( tz );
				arguments.entity.$FORMATTER_CUSTOM.setTimezone( tz );
			}

			// Inject our Array helpers
			arguments.entity.$jARRAYS = variables.jArrays;
		}
	}

	/**
	 * Construct a memento representation from an entity according to it's defined this.memento properties.
	 * You can also override those properties defined in a class by using the arguments in this method.
	 *
	 * @includes       The properties array or list to build the memento with alongside the default includes
	 * @excludes       The properties array or list to exclude from the memento alongside the default excludes
	 * @mappers        A struct of key-function pairs that will map properties to closures/lambadas to process the item value.  The closure will transform the item value.
	 * @defaults       A struct of key-value pairs that denotes the default values for properties if they are null, defaults for everything are a blank string.
	 * @ignoreDefaults If set to true, default includes and excludes will be ignored and only the incoming `includes` and `excludes` list will be used.
	 * @trustedGetters If set to true, getters will not be checked for in the `this` scope before trying to invoke them.
	 * @iso8601Format  If set to true, will use the ISO 8601 standard for formatting dates
	 * @dateMask       The date mask to use when formatting datetimes. Only used if iso8601Format is false.
	 * @timeMask       The time mask to use when formatting datetimes. Only used if iso8601Format is false.
	 * @profile        The profile to use instead of the defaults
	 * @autoCastBooleans Auto cast boolean values if they are not numeric and isBoolean().
	 */
	struct function getMemento(
		includes               = "",
		excludes               = "",
		struct mappers         = {},
		struct defaults        = {},
		boolean ignoreDefaults = false,
		boolean trustedGetters,
		boolean iso8601Format,
		string dateMask,
		string timeMask,
		string profile = "",
		boolean autoCastBooleans
	){
		local.includes = duplicate( arguments.includes );
		local.excludes = duplicate( arguments.excludes );

		// Inflate incoming lists, arrays are faster than lists
		if ( isSimpleValue( local.includes ) ) {
			local.includes = listToArray( local.includes );
		}
		if ( isSimpleValue( local.excludes ) ) {
			local.excludes = listToArray( local.excludes );
		}

		// Param Default Memento Settings
		// We do it here, because ACF caches crap!
		var thisMemento = {
			"autoCastBooleans" : isNull( this.memento.autoCastBooleans ) ? variables.$mementifierSettings.autoCastBooleans : this.memento.autoCastBooleans,
			"dateMask"        : isNull( this.memento.dateMask ) ? variables.$mementifierSettings.dateMask : this.memento.dateMask,
			"defaults"        : isNull( this.memento.defaults ) ? {} : this.memento.defaults,
			"defaultIncludes" : isNull( this.memento.defaultIncludes ) ? [] : this.memento.defaultIncludes,
			"defaultExcludes" : isNull( this.memento.defaultExcludes ) ? [] : this.memento.defaultExcludes,
			"iso8601Format"   : isNull( this.memento.iso8601Format ) ? variables.$mementifierSettings.iso8601Format : this.memento.iso8601Format,
			"mappers"         : isNull( this.memento.mappers ) ? {} : this.memento.mappers,
			"neverInclude"    : isNull( this.memento.neverInclude ) ? [] : this.memento.neverInclude,
			"ormAutoIncludes" : isNull( this.memento.ormAutoIncludes ) ? variables.$mementifierSettings.ormAutoIncludes : this.memento.ormAutoIncludes,
			"profiles"        : isNull( this.memento.profiles ) ? {} : this.memento.profiles,
			"timeMask"        : isNull( this.memento.timeMask ) ? variables.$mementifierSettings.timeMask : this.memento.timeMask,
			"trustedGetters"  : isNull( this.memento.trustedGetters ) ? variables.$mementifierSettings.trustedGetters : this.memento.trustedGetters
		};
		// Param arguments according to instance > settings chain precedence
		param arguments.trustedGetters 		= thisMemento.trustedGetters;
		param arguments.iso8601Format  		= thisMemento.iso8601Format;
		param arguments.dateMask       		= thisMemento.dateMask;
		param arguments.timeMask       		= thisMemento.timeMask;
		param arguments.autoCastBooleans 	= thisMemento.autoCastBooleans;

		// Choose a profile
		if ( len( arguments.profile ) && thisMemento.profiles.keyExists( arguments.profile ) ) {
			structAppend(
				thisMemento,
				thisMemento.profiles[ arguments.profile ],
				true
			);
		}

		// Default formatter or customize it if passed arguments are different than settings.
		var customDateFormatter = this.$FORMATTER_CUSTOM;
		if ( arguments.dateMask != thisMemento.dateMask || arguments.timeMask != thisMemento.timeMask ) {
			customDateFormatter = createObject( "java", "java.text.SimpleDateFormat" ).init(
				"#arguments.dateMask# #arguments.timeMask#"
			);
		}

		// Is orm auto inflate on and no memento defined? Build the default includes using this entity and Hibernate
		if ( thisMemento.ormAutoIncludes && !arrayLen( thisMemento.defaultIncludes ) ) {
			thisMemento.defaultIncludes = $buildOrmIncludes();
		}

		// Do we have a * for auto includes of all properties in the object
		if ( arrayLen( thisMemento.defaultIncludes ) && thisMemento.defaultIncludes[ 1 ] == "*" ) {
			// assign the default includes to be all properties
			// however, we exclude anything with an inject key and anything on the default exclude list
			thisMemento.defaultIncludes = $getDeepProperties()
				.filter( function( item ){
					return (
						!arguments.item.keyExists( "inject" ) &&
						!thisMemento.defaultExcludes.findNoCase( arguments.item.name )
					);
				} )
				.map( function( item ){
					return arguments.item.name;
				} );
		}

		// Incorporate Defaults if not ignored
		if ( !arguments.ignoreDefaults ) {
			local.includes.append( thisMemento.defaultIncludes, true );
			local.excludes.append(
				thisMemento.defaultExcludes.filter( function( item ){
					// Filter out if incoming includes was specified
					return !includes.findNoCase( arguments.item );
				} ),
				true
			);
		}

		// Incorporate Memento Mappers, and Defaults
		thisMemento.mappers.append( arguments.mappers, true );
		thisMemento.defaults.append( arguments.defaults, true );

		// Start processing pipeline on the includes properties
		var result          = {};
		var mappersKeyArray = thisMemento.mappers.keyArray();

		// Filter out exclude items and never include items
		local.includes = local.includes.filter( function( item ){
			return !arrayFindNoCase( excludes, arguments.item )
			&& !arrayFindNoCase( thisMemento.neverInclude, arguments.item )
			&& arguments.item != "";
		} );

		// Make sure includes and excludes are unique
		local.includes = arrayNew( 1 ).append(
			this.$jARRAYS
				.stream( javacast( "java.lang.Object[]", local.includes ) )
				.distinct()
				.toArray(),
			true
		);
		local.excludes = arrayNew( 1 ).append(
			this.$jARRAYS
				.stream( javacast( "java.lang.Object[]", local.excludes ) )
				.distinct()
				.toArray(),
			true
		);

		// Process Includes
		// Please keep at a traditional LOOP to avoid closure reference memory leaks and slowness on some engines.
		for ( var item in local.includes ) {
			var nestedIncludes = "";

			// Is this a nested include?
			if ( listLen( item, "." ) > 1 ) {
				// Nested List by removing relationship root.
				nestedIncludes = listDeleteAt( item, 1, "." );
				// Retrieve the relationship
				item           = listFirst( item, "." );
			}

			// Retrieve Value for transformation: ACF Incompats Suck on elvis operator
			var thisValue = javacast( "null", "" );
			// Do we have a property output alias?
			if ( item.find( ":" ) ) {
				var thisAlias = item.getToken( 2, ":" );
				item          = item.getToken( 1, ":" );
			} else {
				var thisAlias = item;
			}

			if ( arguments.trustedGetters || structKeyExists( this, "get#item#" ) ) {
				try {
					thisValue = invoke( this, "get#item#" );
				} catch ( any e ) {
					// Unless trusted getters is on and there is a mapper for this item rethrow the exception.
					if ( !arguments.trustedGetters || !structKeyExists( arguments.mappers, item ) ) {
						rethrow;
					}
				}
				// If the key doesn't exist and there is no mapper for the item, go to the next item.
			} else if ( !structKeyExists( thisMemento.mappers, item ) ) {
				continue;
			}


			// Verify Nullness
			thisValue = isNull( thisValue ) ? (
				arrayContainsNoCase( thisMemento.defaults.keyArray(), item ) ? (
					isNull( thisMemento.defaults[ item ] ) ? javacast( "null", "" ) : thisMemento.defaults[ item ]
				) : variables.$mementifierSettings.nullDefaultValue
			) : thisValue;

			if ( isNull( thisValue ) ) {
				result[ thisAlias ] = javacast( "null", "" );
			}

			// Match timestamps + date/time objects
			else if (
				isSimpleValue( thisValue )
				&&
				(
					reFind( "^\{ts ([^\}])*\}", thisValue ) // Lucee date format
					||
					reFind( "^\d{4}-\d{2}-\d{2}", thisValue ) // ACF date format begins with YYYY-MM-DD
				)
			) {
				try {
					// Date Test just in case
					thisValue.getTime();
					// Iso Date?
					if ( arguments.iso8601Format ) {
						// we need to convert trailing Zulu time designations offset or JS libs like Moment will not know how to parse it
						result[ thisAlias ] = this.$FORMATTER_ISO8601.format( thisValue ).replace( "Z", "+00:00" );
					} else {
						result[ thisAlias ] = customDateFormatter.format( thisValue );
					}
				} catch ( any e ) {
					result[ thisAlias ] = thisValue;
				}
			}

			// Strict Type Boolean Values
			else if ( arguments.autoCastBooleans && !isNumeric( thisValue ) && isBoolean( thisValue ) ) {
				result[ thisAlias ] = javacast( "Boolean", thisValue );
			}

			// Simple Values
			else if ( isSimpleValue( thisValue ) ) {
				result[ thisAlias ] = thisValue;
			}

			// Array Collections
			else if ( isArray( thisValue ) ) {
				// Map Items into result object
				result[ thisAlias ] = [];
				// Again we use traditional loops to avoid closure references and slowness on some engines
				for ( var thisIndex = 1; thisIndex <= arrayLen( thisValue ); thisIndex++ ) {
					// only get mementos from relationships that have mementos, in the event that we have an already-serialized array of structs
					if (
						!isSimpleValue( thisValue[ thisIndex ] ) && structKeyExists(
							thisValue[ thisIndex ],
							"getMemento"
						)
					) {
						// If no nested includes requested, then default them
						var nestedIncludes = $buildNestedMementoList( includes, item );

						// Process the item memento
						result[ thisAlias ][ thisIndex ] = thisValue[ thisIndex ].getMemento(
							includes      : nestedIncludes,
							excludes      : $buildNestedMementoList( excludes, item ),
							mappers       : $buildNestedMementoStruct( mappers, item ),
							defaults      : $buildNestedMementoStruct( defaults, item ),
							// cascade the ignore defaults down if specific nested includes are requested
							ignoreDefaults: nestedIncludes.len() ? arguments.ignoreDefaults : false,
							// Cascade the arguments to the children
							profile       : arguments.profile,
							trustedGetters: arguments.trustedGetters,
							iso8601Format : arguments.iso8601Format,
							dateMask      : arguments.dateMask,
							timeMask      : arguments.timeMask,
							autoCastBooleans : arguments.autoCastBooleans
						);
					} else {
						result[ thisAlias ][ thisIndex ] = thisValue[ thisIndex ];
					}
				}
			}

			// Single Object Relationships
			else if ( isValid( "component", thisValue ) && structKeyExists( thisValue, "getMemento" ) ) {
				// writeDump( var=$buildNestedMementoList( includes, item ), label="includes: #item#" );
				// writeDump( var=$buildNestedMementoList( excludes, item ), label="excludes: #item#" );

				// If no nested includes requested, then default them
				var nestedIncludes = $buildNestedMementoList( includes, item );

				// Process the item memento
				var thisItemMemento = thisValue.getMemento(
					includes      	: nestedIncludes,
					excludes      	: $buildNestedMementoList( excludes, item ),
					mappers       	: $buildNestedMementoStruct( mappers, item ),
					defaults      	: $buildNestedMementoStruct( defaults, item ),
					// cascade the ignore defaults down if specific nested includes are requested
					ignoreDefaults	: nestedIncludes.len() ? arguments.ignoreDefaults : false,
					// Cascade the arguments to the children
					profile       		: arguments.profile,
					trustedGetters		: arguments.trustedGetters,
					iso8601Format 		: arguments.iso8601Format,
					dateMask      		: arguments.dateMask,
					timeMask      		: arguments.timeMask,
					autoCastBooleans : arguments.autoCastBooleans
				);

				// Do we have a root already for this guy?
				if ( result.keyExists( thisAlias ) ) {
					structAppend( result[ thisAlias ], thisItemMemento, false );
				} else {
					result[ thisAlias ] = thisItemMemento;
				}
			} 


			// we don't know what to do with this item so we return as-is
			else {
				result[ thisAlias ] = thisValue;
			}
		}

		// This cannot use functional approaches like result.map() due to
		// slowness on some engines ( Adobe :( ) and also closure pointers that cause
		// memory leaks, especially when dealing with ORM engines. Please keep at a traditional loop
		for ( var item in result ) {
			// Do we have a mapper according to this key?
			if ( mappersKeyArray.findNoCase( item ) ) {
				// ACF compat
				var thisMapper = thisMemento.mappers[ item ];
				// Transform it
				result[ item ] = thisMapper( result[ item ], result );
			} else {
				// Check for null values
				result[ item ] = ( !result.keyExists( item ) || isNull( result[ item ] ) ) ? javacast( "null", "" ) : result[
					item
				];
			}
		}

		// Return memento
		return result;
	}

	/**
	 * This function builds automatic ORM entity includes
	 *
	 * @return The array of default includes for the ORM entity where this function is injected into
	 */
	array function $buildOrmIncludes(){
		var thisName = isNull( variables.entityName ) ? "" : variables.entityName;
		if ( !len( thisName ) ) {
			var md   = getMetadata( this );
			thisName = ( md.keyExists( "entityName" ) ? md.entityName : listLast( md.name, "." ) );
		}

		var ORMService = new cborm.models.BaseORMService();
		var entityMd   = ORMService.getEntityMetadata( this );
		var types      = entityMd.getPropertyTypes();
		var typeMap    = arrayReduce(
			entityMd.getPropertyNames(),
			function( mdTypes, propertyName, index ){
				arguments.mdTypes[ arguments.propertyName ] = types[ index ].getClass().getName();
				return arguments.mdTypes;
			},
			{}
		);

		var defaultIncludes = typeMap
			.keyArray()
			.filter( function( propertyName ){
				switch ( listLast( typeMap[ arguments.propertyName ], "." ) ) {
					case "BagType":
					case "OneToManyType":
					case "ManyToManyType":
					case "ManyToOneType":
					case "OneToOneType":
					case "BinaryType": {
						return false;
					}
					default: {
						return true;
					}
				}
			} );

		// Append primary keys
		if ( entityMd.hasIdentifierProperty() ) {
			arrayAppend( defaultIncludes, entityMd.getIdentifierPropertyName() );
		} else if ( entityMd.getIdentifierType().isComponentType() ) {
			arrayAppend(
				defaultIncludes,
				listToArray( arrayToList( entityMd.getIdentifierType().getPropertyNames() ) ),
				true
			);
		}

		return defaultIncludes;
	}

	/**
	 * Build a new memento include/exclude list using the target list and a property root
	 *
	 * @list The list to use for construction
	 * @root The root to filter out
	 *
	 * @return A string list of the new hiearchy to use
	 */
	function $buildNestedMementoList( required list, required root ){
		return arguments.list
			.filter( function( target ){
				return listFirst( arguments.target, "." ) == root && listLen( arguments.target, "." ) > 1;
			} )
			.map( function( target ){
				return listDeleteAt( arguments.target, 1, "." );
			} );

		// var results = [];
		// for( var target in arguments.list ){
		// 	if( listFirst( target, "." ) == root && listLen( target, "." ) > 1 ){
		// 		results.append( target.listDeleteAt( 1, "." ) );
		// 	}
		// }
		// return results;
	}

	/**
	 * Build a new memento mappers/defaults struct using the target list and a property root
	 *
	 * @struct The struct to use for construction
	 * @root   The root to filter out
	 *
	 * @return A struct of the new hiearchy to use
	 */
	function $buildNestedMementoStruct( required struct s, required string root ){
		return arguments.s.reduce( function( acc, key, value ){
			if ( listFirst( arguments.key, "." ) == root && listLen( arguments.key, "." ) > 1 ) {
				arguments.acc[ listDeleteAt( arguments.key, 1, "." ) ] = arguments.value;
			}
			return arguments.acc;
		}, {} );
	}

	/**
	 * Inject mixins into target scopes
	 */
	function $injectMixin( name, target ){
		variables[ arguments.name ] = arguments.target;
		this[ arguments.name ]      = arguments.target;
		return this;
	}

	/**
	 * Get Deep Properties
	 * Returns an array of an objects properties including those inherited by base classes.
	 *
	 * @metaData (optional) The starting CFML metadata of the entity object. Defaults to the current object.
	 *
	 * @return an array of object properties
	 */
	private array function $getDeepProperties( struct metaData = getMetadata( this ) ){
		var properties = [];

		// if this object extends another object, append any inherited properties.
		if (
			structKeyExists( arguments.metaData, "extends" ) &&
			structKeyExists( arguments.metaData.extends, "properties" )
		) {
			properties.append( $getDeepProperties( arguments.metaData.extends ), true );
		}

		// if this object has properties, append them.
		if ( structKeyExists( arguments.metaData, "properties" ) ) {
			properties.append( arguments.metadata.properties, true );
		}

		return properties;
	}

}
