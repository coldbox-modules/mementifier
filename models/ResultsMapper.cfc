/**
 * The result mapper is an object that will behave in much manner to how cffractel created a resultmap
 * of a struct keyed by the identifier and an array of identifiers
 *
 * <pre>
 * data = {
 * "results" = [],
 * "resultsMap" = {
 *
 * }
 * }
 * </pre>
 */
component singleton {

	/**
	 * Constructor
	 */
	function init(){
		return this;
	}

	/**
	 * Construct a memento representation using a results map. This process will iterate over the collection and create a
	 * results array with all the identifiers and a struct keyed by identifier of the mememnto data.
	 *
	 * @collection     The target collection
	 * @id             The identifier key, defaults to `id` for simplicity.
	 * @includes       The properties array or list to build the memento with alongside the default includes
	 * @excludes       The properties array or list to exclude from the memento alongside the default excludes
	 * @mappers        A struct of key-function pairs that will map properties to closures/lambadas to process the item value.  The closure will transform the item value.
	 * @defaults       A struct of key-value pairs that denotes the default values for properties if they are null, defaults for everything are a blank string.
	 * @ignoreDefaults If set to true, default includes and excludes will be ignored and only the incoming `includes` and `excludes` list will be used.
	 * @trustedGetters If set to true, getters will not be checked for in the `this` scope before trying to invoke them.
	 *
	 * @return struct of { results = [], resultsMap = {} }
	 */
	function process(
		required array collection,
		id                     = "id",
		includes               = "",
		excludes               = "",
		struct mappers         = {},
		struct defaults        = {},
		boolean ignoreDefaults = false,
		boolean trustedGetters
	){
		var args = arguments;
		return arguments.collection.reduce( function( accumulator, item ){
			var id = invoke( arguments.item, "get#id#" );
			arguments.accumulator.results.append( id );
			arguments.accumulator.resultsMap[ id ] = item.getMemento( argumentCollection = args );
			return arguments.accumulator;
		}, { "results" : [], "resultsMap" : {} } );
	}

}
