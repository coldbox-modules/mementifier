component extends="coldbox.system.testing.BaseInterceptorTest" interceptor="mementifier.interceptors.Mementifier" {

	function beforeAll(){
		super.beforeAll();

		setup();

		variables.moduleSettings = {
			// Turn on to use the ISO8601 date/time formatting on all processed date/time properites, else use the masks
			iso8601Format     : false,
			// The default date mask to use for date properties
			dateMask          : "yyyy-MM-dd",
			// The default time mask to use for date properties
			timeMask          : "HH:mm:ss",
			// Enable orm auto default includes: If true and an object doesn't have any `memento` struct defined
			// this module will create it with all properties and relationships it can find for the target entity
			// leveraging the cborm module.
			ormAutoIncludes   : true,
			// The default value for getters which return null
			nullDefaultValue  : "",
			// Don't check for getters before invoking them
			trustedGetters    : false,
			// If not empty, convert all date/times to the specific timezone
			convertToTimezone : ""
		};

		variables.interceptor.$property(
			"settings",
			"variables",
			variables.moduleSettings
		);

		variables.interceptor.configure();

		var mockData = {
			fname       : "testuser",
			lname       : "testuser",
			email       : "testuser@testuser.com",
			username    : "testuser",
			isConfirmed : true,
			isActive    : true,
			otherURL    : "www.luismajano.com"
		};

		variables.testModel = getMockBox().prepareMock( entityNew( "User", mockData ) );
		variables.interceptor.afterInstanceCreation( { target : variables.testModel } );
	}

	function run(){
		describe( "Mementifier", function(){
			it( "Won't modify includes/excludes arrays", function(){
				var includesList = "userId,blogUrl,fname:firstName,lname:lastName";
				var excludesList = "userId,blogUrl,fname:firstName,lname:lastName";

				var includesArray = listToArray( includesList );
				var excludesArray = listToArray( excludesList );

				var memento = variables.testModel.getMemento( includesArray, excludesArray );

				expect( arrayLen( includesArray ) ).toBe( listLen( includesList ) );
				expect( arrayLen( excludesArray ) ).toBe( listLen( excludesList ) );
			} );
			it( "Won't call the same getter twice", function(){
				variables.testModel.$(
					method      = "getBlogURL",
					returns     = "https://michaelborn.me",
					callLogging = true
				);
				var memento = variables.testModel.getMemento( "blogUrl" );

				expect( variables.testModel.$once( "getBlogURL" ) ).toBeTrue();
			} );
			it( "Should include all items from defaultIncludes", function(){
				var memento = variables.testModel.getMemento( "userId" );

				expect( memento ).toBeTypeOf( "struct" ).toHaveKey( "userId,blogUrl,firstName,lastName" );
			} );
			it( "Should exclude any explicit excludes", function(){
				var memento = variables.testModel.getMemento( "APIToken", "userId,blogUrl,firstName,lastName" );

				expect( memento )
					.toBeTypeOf( "struct" )
					.toHaveKey( "APIToken" )
					.nottoHaveKey( "userId,blogUrl,firstName,lastName" );
			} );
			it( "Should not be possible to include neverIncludes", function(){
				var memento = variables.testModel.getMemento( "password" );

				expect( memento ).toBeTypeOf( "struct" ).notToHaveKey( "password" );
			} );
			it( "should not process empty string include", function(){
				variables.testModel.$( method = "get", callLogging = true );

				variables.testModel.getMemento();
				expect( variables.testModel.$never( "get" ) ).toBeTrue();
			} );
		} );
	}

}
