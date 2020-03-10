/**
 * Listen to various entity methods so we can inject our mementifying capabilties to objects.
 * If an object already has a `getMemento()` method, we will inject a `$getMemento()` method so you can still decorate it.
 */
component{

	property name="settings" inject="coldbox:moduleSettings:mementifier";

	/**
	 * Configure interceptor
	 */
	function configure(){
	}

	/*********************************** WIREBOX EVENTS ***********************************/

	/**
	 * Listen to object creations
	 */
	function afterInstanceCreation( interceptData ){
		// Only process struct based objects with the `memento` property
		if( isStruct( arguments.interceptData.target ) && structKeyExists( arguments.interceptData.target, "memento" ) ){
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
		if(
			!structKeyExists( arguments.entity, "$mementifierSettings" )
		){
			//systemOutput( "==> Injectin mementifier: #getMetadata( arguments.entity ).name# ", true );
			// Inject utility
			arguments.entity.$injectMixin = variables.$injectMixin;
			// Inject Settings
			arguments.entity.$injectMixin( "$mementifierSettings", variables.settings );

			// Inject getMemento if not overriden
			if( !structKeyExists( arguments.entity, "getMemento" ) ){
				arguments.entity.$injectMixin( "getMemento", variables.getMemento );
			}
			// Else inject it with the $getMemento alias
			else {
				arguments.entity.$injectMixin( "$getMemento", variables.getMemento );
			}

			// Inject helper methods
            arguments.entity.$injectMixin( "$buildNestedMementoList", variables.$buildNestedMementoList );
            arguments.entity.$injectMixin( "$getDeepProperties", variables.$getDeepProperties );
			// We do simple date formatters as they are faster than CFML methods
			arguments.entity.$FORMATTER_ISO8601 = createObject( "java", "java.text.SimpleDateFormat" ).init( "yyyy-MM-dd'T'HH:mm:ssXXX" );
			arguments.entity.$FORMATTER_CUSTOM 	= createObject( "java", "java.text.SimpleDateFormat" ).init( "#settings.dateMask# #settings.timeMask#" );
		}
	}

	/**
	 * Construct a memento representation from an entity according to includes and exclude lists
	 *
	 * @includes The properties array or list to build the memento with alongside the default includes
	 * @excludes The properties array or list to exclude from the memento alongside the default excludes
	 * @mappers A struct of key-function pairs that will map properties to closures/lambadas to process the item value.  The closure will transform the item value.
	 * @defaults A struct of key-value pairs that denotes the default values for properties if they are null, defaults for everything are a blank string.
	 * @ignoreDefaults If set to true, default includes and excludes will be ignored and only the incoming `includes` and `excludes` list will be used.
	 * @trustedGetters If set to true, getters will not be checked for in the `this` scope before trying to invoke them.
	 */
	struct function getMemento(
		includes="",
		excludes="",
		struct mappers={},
		struct defaults={},
        boolean ignoreDefaults=false,
        boolean trustedGetters
	){
		// Inflate incoming lists, arrays are faster than lists
		if( isSimpleValue( arguments.includes ) ){
			arguments.includes = listToArray( arguments.includes );
		}
		if( isSimpleValue( arguments.excludes ) ){
			arguments.excludes = listToArray( arguments.excludes );
		}

		// Param Default Memento Settings
		// We do it here, because ACF caches crap!
		var thisMemento = {
			"defaultIncludes" 	: isNull( this.memento.defaultIncludes ) 	? []                                   : this.memento.defaultIncludes,
			"defaultExcludes" 	: isNull( this.memento.defaultExcludes ) 	? []                                   : this.memento.defaultExcludes,
			"neverInclude"		: isNull( this.memento.neverInclude ) 		? []                                   : this.memento.neverInclude,
			"mappers"      		: isNull( this.memento.mappers ) 			? {}                                   : this.memento.mappers,
			"defaults"     		: isNull( this.memento.defaults ) 			? {}                                   : this.memento.defaults,
			"trustedGetters"    : isNull( this.memento.trustedGetters )     ? $mementifierSettings.trustedGetters  : this.memento.trustedGetters,
			"ormAutoIncludes"   : isNull( this.memento.ormAutoIncludes )    ? $mementifierSettings.ormAutoIncludes : this.memento.ormAutoIncludes
        };

        param arguments.trustedGetters = thisMemento.trustedGetters;

		// Is orm auto inflate on and no memento defined? Build the default includes using this entity and Hibernate
		if( thisMemento.ormAutoIncludes && !arrayLen( thisMemento.defaultIncludes ) ){
			var thisName = isNull( variables.entityName ) ? "" : variables.entityName;
			if( ! len( thisName ) ){
				var md = getMetadata( this );
				thisName = ( md.keyExists( "entityName" ) ? md.entityName : listLast( md.name, "." ) );
			}

			var ORMService = new cborm.models.BaseORMService();

			var entityMd = ORMService.getEntityMetadata( this );
			var typeMap = arrayReduce(
								entityMd.getPropertyNames(),
								function( mdTypes, propertyName ){
									var propertyType = entityMd.getPropertyType( propertyName );
									var propertyClassName = getMetadata( propertyType ).name;

									mdTypes[ propertyName ] = propertyClassName;
									return mdTypes;
								}
								,{});

			thisMemento.defaultIncludes = typeMap.keyArray().filter( function( propertyName ){
					switch( listLast( typeMap[ propertyName ], "." ) ){
						case "BagType":
                    	case "OneToManyType":
						case "ManyToManyType":
						case "ManyToOneType":
						case "OneToOneType":
						case "BinaryType":{
                          return false;
                    	}
						default:{
						  return true;
						}
					}
			} );

			// Append primary keys
			if( entityMd.hasIdentifierProperty() ){
				arrayAppend( thisMemento.defaultIncludes, entityMd.getIdentifierPropertyName() );
			} else if( thisMemento.defaultIncludes.getIdentifierType().isComponentType() ){
				arrayAppend( thisMemento.defaultIncludes, listToArray( arrayToList( entityMd.getIdentifierType().getPropertyNames() ) ), true );
			}
		}

		// Do we have a * for auto includes of all properties in the object
		if( arrayLen( thisMemento.defaultIncludes ) && thisMemento.defaultIncludes[ 1 ] == "*" ){

            // assign the default includes to be all properties
            // however, we exclude anything with an inject key and anything on the default exclude list
            thisMemento.defaultIncludes = $getDeepProperties()
				.filter( function( item ){
					return (
                        !item.keyExists( "inject" ) &&
                        !thisMemento.defaultExcludes.findNoCase( item.name )
                    );
				} ).map( function( item ){
					return item.name;
                } );

		}

		// Incorporate Defaults if not ignored
		if( !arguments.ignoreDefaults ){
			arguments.includes.append( thisMemento.defaultIncludes, true );
			arguments.excludes.append(
				thisMemento.defaultExcludes.filter( function( item ){
					// Filter out if incoming includes was specified
					return !includes.findNoCase( item );
				} ),
				true
            );
		}

		// Incorporate Memento Mappers, and Defaults
		thisMemento.mappers.append( arguments.mappers, true );
		thisMemento.defaults.append( arguments.defaults, true );

		// Start processing pipeline on the includes properties
		var result 			= {};
		var mappersKeyArray = thisMemento.mappers.keyArray();

		// Filter out exclude items and never include items
		arguments.includes = arguments.includes.filter( function( item ){
			return !arrayFindNoCase( excludes, item ) && !arrayFindNoCase( thisMemento.neverInclude, item );
        } );

		// Process Includes
		for( var item in arguments.includes ){

			// writeDump( var="Processing: #item#" );abort;

			// Is this a nested include?
			if( listLen( item,  "." ) > 1 ){
				// Retrieve the relationship
				item = listFirst( item, "." );
            }

            // Retrieve Value for transformation: ACF Incompats Suck on elvis operator
            var thisValue = javacast( "null", "" );

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
			} else if ( !structKeyExists( arguments.mappers, item ) ) {
                continue;
            }

            // Verify Nullness
            thisValue = isNull( thisValue ) ? (
                structKeyExists( thisMemento.defaults, item ) ? thisMemento.defaults[ item ] : $mementifierSettings.nullDefaultValue
            ) : thisValue;

			// Match timestamps + date/time objects
			if(
				isSimpleValue( thisValue )
				&&
				(
					reFind( "^\{ts ([^\}])*\}", thisValue ) // Lucee date format
					||
					reFind( "^\d{4}-\d{2}-\d{2}", thisValue ) // ACF date format begins with YYYY-MM-DD
				)
			){
				try{
					// Date Test just in case
					thisValue.getTime();
					// Iso Date?
					if( $mementifierSettings.iso8601Format ){
						// we need to convert trailing Zulu time designations offset or JS libs like Moment will not know how to parse it
						result[ item ] = this.$FORMATTER_ISO8601.format( thisValue ).replace("Z", "+00:00");
					} else {
						result[ item ] = this.$FORMATTER_CUSTOM.format( thisValue );
					}
				} catch( any e ){
					result[ item ] = thisValue;
				}
			}
			// Strict Type Boolean Values
			else if( !isNumeric( thisValue ) && isBoolean( thisValue ) ){
				result[ item ] = javaCast( "Boolean", thisValue );
			}
			// Simple Values
			else if( isSimpleValue( thisValue ) ){
				result[ item ] = thisValue;
			}

			// Array Collections
			else if( isArray( thisValue ) ){
				// Map Items into result object
				result[ item ] = [];
				for( var thisIndex = 1; thisIndex <= arrayLen( thisValue ); thisIndex++ ){
					 // only get mementos from relationships that have mementos, in the event that we have an already-serialized array of structs
					if( !isSimpleValue( thisValue[ thisIndex ] ) && structKeyExists( thisValue[ thisIndex ], "getMemento" ) ) {
						var nestedIncludes = $buildNestedMementoList( includes, item );
						result[ item ][ thisIndex ] = thisValue[ thisIndex ].getMemento(
							includes 		= nestedIncludes,
							excludes 		= $buildNestedMementoList( excludes, item ),
							mappers 		= mappers,
							defaults 		= defaults,
							// cascade the ignore defaults down if specific nested includes are requested
							ignoreDefaults 	= nestedIncludes.len() ? ignoreDefaults : false
						);

					} else {
						result[ item ][ thisIndex ] = thisValue [ thisIndex ];
					}
				}
			}

			// Single Object Relationships
			else if( isValid( 'component', thisValue ) && structKeyExists( thisValue, "getMemento" ) ){
				//writeDump( var=$buildNestedMementoList( includes, item ), label="includes: #item#" );
				//writeDump( var=$buildNestedMementoList( excludes, item ), label="excludes: #item#" );
				var nestedIncludes = $buildNestedMementoList( includes, item );
				result[ item ] = thisValue.getMemento(
					includes 		= nestedIncludes,
					excludes 		= $buildNestedMementoList( excludes, item ),
					mappers 		= mappers,
					defaults 		= defaults,
					// cascade the ignore defaults down if specific nested includes are requested
					ignoreDefaults 	= nestedIncludes.len() ? ignoreDefaults : false
				);
			} else {
				// we don't know what to do with this item so we return as-is
				result[ item ] = thisValue;
            }
        }

        return result.map( function( key, value ) {
            if ( mappersKeyArray.findNoCase( key ) ) {
                // ACF compat
				var thisMapper = thisMemento.mappers[ key ];
				return thisMapper( value, result );
            } else {
                return value;
            }
        } );

		return result;
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
				return listFirst( target, "." ) == root && listLen( target, "." ) > 1;
			} )
			.map( function( target ){
				return listDeleteAt( target, 1, "." );
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
	 * Inject mixins into target scopes
	 */
	function $injectMixin( name, target ){
		variables[ arguments.name ] = arguments.target;
		this[ arguments.name ] 		= arguments.target;
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
    private array function $getDeepProperties( struct metaData = getMetaData( this ) ) {

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
