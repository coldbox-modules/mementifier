component {

	moduleRoot = createObject( "java", "java.io.File" )
		.init( getDirectoryFromPath( getCurrentTemplatePath() ) & "../../../" )
		.getCanonicalPath();

	this.name                       = "mementifier-full-null-regression-#hash( moduleRoot )#";
	this.enableNullSupport          = true;
	this.mappings[ "/mementifier" ] = moduleRoot;
	this.mappings[ "/fullnull" ]    = getDirectoryFromPath( getCurrentTemplatePath() );

}
