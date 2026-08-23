component extends="mementifier.interceptors.Mementifier" {

	function init( required struct settings ){
		variables.settings = arguments.settings;
		configure();
		return this;
	}

}
