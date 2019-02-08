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
	 */
	struct function getMemento(
		includes="",
		excludes="",
		struct mappers={},
		struct defaults={},
		boolean ignoreDefaults=false
	){
		// Inflate incoming lists, arrays are faster than lists
		if( isSimpleValue( arguments.includes ) ){
			arguments.includes = listToArray( arguments.includes );
		}
		if( isSimpleValue( arguments.excludes ) ){
			arguments.excludes = listToArray( arguments.excludes );
		}

		// Is orm auto inflate on and no memento defined? Build the default includes using this entity and Hibernate
		if( $mementifierSettings.ormAutoIncludes && isNull( this.memento.defaultIncludes ) ){
			var entityName = variables.entityName ?: "";
			if( !entityName.len() ){
				var md = getMetadata( this );
				entityName = ( md.keyExists( "entityName" ) ? md.entityName : listLast( md.name, "." ) );
			}
			this.memento.defaultIncludes = ormGetSessionFactory()
				.getClassMetaData( entityName )
				.getPropertyNames();
		}

		// Param Default Memento Settings
		param this.memento.defaultIncludes 	= [];
		param this.memento.defaultExcludes 	= [];
		param this.memento.neverInclude		= [];
		param this.memento.mappers      	= {};
		param this.memento.defaults     	= {};

		// Incorporate Defaults if not ignored
		if( !arguments.ignoreDefaults ){
			arguments.includes.append( this.memento.defaultIncludes, true );
			arguments.excludes.append(
				this.memento.defaultExcludes.filter( function( item ){
					// Filter out if incoming includes was specified
					return !includes.findNoCase( item );
				} ),
				true
			);
		}

		// Incorporate Memento Mappers, and Defaults
		this.memento.mappers.append( arguments.mappers, true );
		this.memento.defaults.append( arguments.defaults, true );

		// Start processing pipeline on the includes properties
		var result 			= {};
		var mappersKeyArray = this.memento.mappers.keyArray();

		// Filter out exclude items and never include items
		arguments.includes = arguments.includes.filter( function( item ){
			return !arrayFindNoCase( excludes, item ) && !arrayFindNoCase( this.memento.neverInclude, item );
		} );

		//writeDump( var=arguments.includes, label="Processing Includes: #this.pk#" );abort;

		// Process Includes
		for( var item in arguments.includes ){

			//writeDump( var="Processing: #item#" );

			// Is this a nested include?
			if( item.listLen( "." ) > 1 ){
				// Retrieve the relationship
				item = item.listFirst( "." );
			}

			// Retrieve Value for transformation: ACF Incompats Suck on elvis operator
			if( structKeyExists( this, "get#item#" ) ){
				var thisValue = invoke( this, "get#item#" );
				// Verify Nullness
				thisValue = isNull( thisValue ) ? (
					structKeyExists( this.memento.defaults, item ) ? this.memento.defaults[ item ] : ""
				) : thisValue;
			} else {
				// Calling for non-existent properties, skip out
				continue;
			}

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
			if( isArray( thisValue ) ){
				// Map Items into result object
				result[ item ] = [];
				for( var thisIndex = 1; thisIndex <= arrayLen( thisValue ); thisIndex++ ){
					result[ item ][ thisIndex ] = thisValue[ thisIndex ].getMemento(
						includes 		= $buildNestedMementoList( includes, item ),
						excludes 		= $buildNestedMementoList( excludes, item ),
						mappers 		= mappers,
						defaults 		= defaults,
						ignoreDefaults 	= ignoreDefaults
					);
				}
			}

			// Single Object Relationships
			if( isObject( thisValue ) ){
				//writeDump( var=$buildNestedMementoList( includes, item ), label="includes: #item#" );
				//writeDump( var=$buildNestedMementoList( excludes, item ), label="excludes: #item#" );
				result[ item ] = thisValue.getMemento(
					includes 		= $buildNestedMementoList( includes, item ),
					excludes 		= $buildNestedMementoList( excludes, item ),
					mappers 		= mappers,
					defaults 		= defaults,
					ignoreDefaults 	= ignoreDefaults
				);
			}

			// Result Mapper for Item Result
			if( mappersKeyArray.findNoCase( item ) ){
				// ACF compat
				var thisMapper = this.memento.mappers[ item ];
				result[ item ] = thisMapper( result[ item ] );
			}


			// ensure anything left over is provided as the value
			if( !structKeyExists( result, item ) ){
				result[ item ] = thisValue;
			}

		}

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
				return target.listDeleteAt( 1, "." );
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
}
