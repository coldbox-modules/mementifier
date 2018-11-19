/**
 * Module Configuration
 */
component {

	// Module Properties
	this.title 				= "mementifier";
	this.author 			= "Ortus Solutions, Corp";
	this.description 		= "Assist with extracting memento from objects";
	// Model Namespace
	this.modelNamespace		= "mementifier";
	// CF Mapping
	this.cfmapping			= "mementifier";
	// Auto-map models
	this.autoMapModels		= true;
	// Module Dependencies
	this.dependencies 		= [];

	/**
	 * Configure
	 */
	function configure(){

		// module settings - stored in modules.name.settings
		settings = {
			// Turn on to use the ISO8601 date/time formatting on all processed date/time properites, else use the masks
			iso8601Format = false,
			// The default date mask to use for date properties
			dateMask      = "yyyy-mm-dd",
			// The default time mask to use for date properties
			timeMask      = "HH:mm:ss"
		};

		// Custom Declared Interceptors
		interceptors = [
			{ class="#moduleMapping#.interceptors.mementifier" }
		];
	}

	/**
	* Fired when the module is registered and activated.
	*/
	function onLoad(){

	}

	/**
	* Fired when the module is unregistered and unloaded
	*/
	function onUnload(){

	}

}