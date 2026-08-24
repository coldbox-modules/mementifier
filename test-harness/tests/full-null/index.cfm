<cfsetting showDebugOutput="false">
<cfscript>
settings = {
	iso8601Format     : false,
	dateMask          : "yyyy-MM-dd",
	timeMask          : "HH:mm:ss",
	ormAutoIncludes   : false,
	nullDefaultValue  : "",
	trustedGetters    : false,
	convertToTimezone : "",
	autoCastBooleans  : true
};

model       = new fullnull.PartialMemento();
interceptor = new fullnull.TestMementifier( settings );
interceptor.processMemento( model );
memento = model.getMemento();

if ( !memento.keyExists( "id" ) || memento.id != "partial-memento" ) {
	throw( type = "RegressionFailure", message = "Partial memento settings failed with full null support." );
}

writeOutput( "PASS" );
</cfscript>
