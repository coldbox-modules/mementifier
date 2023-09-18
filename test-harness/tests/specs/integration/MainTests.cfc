﻿component extends="coldbox.system.testing.BaseTestCase" {

	function run(){
		describe( "Mementifier", function(){
			beforeEach( function( currentSpec ){
				setup();
			} );

			it( "can render base mementos", function(){
				var event   = this.request( route = "/main/index", params = {} );
				var memento = deserializeJSON( event.getRenderedContent() );
				// Derfault INcludes + Excludes
				expect( memento )
					.toBeStruct()
					.notToHaveKey( "role" )
					.notToHaveKey( "permission" );
				// mapper
				expect( memento.lastName ).toBe( "TESTUSER" );
			} );

			it( "can render mementos even if the object has already-serialized data", function(){
				var event = this.request(
					route  = "/main/alreadySerialized",
					params = { "includes" : "alreadySerialized" }
				);
				var memento = deserializeJSON( event.getRenderedContent() );
				// Derfault INcludes + Excludes

				expect( memento[ "alreadySerialized" ] ).toBeArray().toHaveLength( 2 );

				expect( memento[ "alreadySerialized" ][ 1 ] ).toBeStruct().toHaveKey( "foo" );

				expect( memento[ "alreadySerialized" ][ 2 ] ).toBeStruct().toHaveKey( "baz" );

				expect( memento[ "alreadySerialized" ][ 1 ][ "foo" ] ).toBe( "bar" );
			} );


			it( "can process a resultsMap", function(){
				var results = this.request( route = "/main/resultMap" ).getValue( "cbox_handler_results" );

				expect( results ).toHaveKey( "results" ).toHaveKey( "resultsMap" );
				expect( results.resultsMap ).toHaveKey( results.results[ 1 ] );
			} );


			it( "can render inherited properties with wildcard default properties", function(){
				var event = this.request( route = "/main/index", params = { "includes" : "createdDate,isActive" } );

				var memento = deserializeJSON( event.getRenderedContent() );

				// Expect inherited properties from the base class
				expect( memento )
					.toBeStruct()
					.toHaveKey( "createdDate,isActive" )
					.notToHaveKey( "modifiedDate" );
			} );

			it( "can use a mapper for a property that does not exist", function(){
				var event = this.request( route = "/main/index", params = { "includes" : "foo" } );

				var memento = deserializeJSON( event.getRenderedContent() );

				// Expect inherited properties from the base class
				expect( memento ).toBeStruct();
				expect( memento ).toHaveKey( "foo" );
				expect( memento.foo ).toBe( memento.firstName & " " & memento.lastName );
			} );

			it( "skips properties that do not exist and do not have a mapper", function(){
				var event = this.request( route = "/main/index", params = { "includes" : "doesntexist" } );

				var memento = deserializeJSON( event.getRenderedContent() );

				// Expect inherited properties from the base class
				expect( memento ).toBeStruct();
				expect( memento ).notToHaveKey( "doesntexist" );
			} );

			it( "tries to retrieve all properties when trustedGetters is on even if the method does not seem to exist", function(){
				var event = this.request(
					route  = "/main/index",
					params = { "includes" : "doesntexist", "trustedGetters" : true }
				);

				var memento = deserializeJSON( event.getRenderedContent() );

				expect( memento ).toBeStruct();
				expect( memento ).toHaveKey( "doesntexist" );
				expect( memento.doesntexist ).toBe( "doesntexist" );
			} );

			it( "can specify iso8601 in the getMemento call", function(){
				var event = this.request(
					route  = "/main/index",
					params = { "includes" : "createdDate", "iso8601Format" : true }
				);

				var memento = deserializeJSON( event.getRenderedContent() );
				expect( memento ).toBeStruct();
				expect( memento ).toHaveKey( "createdDate" );
				expect( memento.createdDate ).toInclude( "T" );
			} );

			it( "can specify a date mask in the getMemento call", function(){
				var event = this.request(
					route  = "/main/index",
					params = { "includes" : "createdDate", "dateMask" : "MMM d YYYY" }
				);

				var memento = deserializeJSON( event.getRenderedContent() );
				expect( memento ).toBeStruct();
				expect( memento ).toHaveKey( "createdDate" );
				expect( listToArray( memento.createdDate, "" )[ 1 ] ).notToBeNumeric();
			} );

			it( "can specify a time mask in the getMemento call", function(){
				var event = this.request(
					route  = "/main/index",
					params = { "includes" : "createdDate", "timeMask" : "H" }
				);

				var memento = deserializeJSON( event.getRenderedContent() );
				expect( memento ).toBeStruct();
				expect( memento ).toHaveKey( "createdDate" );
				expect( find( ":", memento.createdDate ) > 0 ).toBeFalse( "Should not find a : character." );
			} );

			it( "correctly passes nested mappers", function(){
				expect( function(){
					var event = this.request( route = "/main/nested", params = {} );

					var memento = deserializeJSON( event.getRenderedContent() );
					expect( memento.role.permissions[ 1 ].description ).toBeWithCase( "READ" );
					expect( memento.role.permissions[ 2 ].description ).toBeWithCase( "WRITE" );
				} ).notToThrow();
			} );

			it( "can use property aliases for includes", function(){
				var event   = this.request( route = "/main/index", params = { includes : "APIToken:token" } );
				var memento = deserializeJSON( event.getRenderedContent() );
				expect( memento ).toHaveKey( "token,firstName,lastName" );
			} );

			it( "Will use default includes if none specified", function(){
				var event   = this.request( route = "/main/post", params = {} );
				var memento = deserializeJSON( event.getRenderedContent() );
				expect( memento ).toHaveKey( "slug,title,teaser,isActive,createdDate,updatedDate,postId" );
				expect( memento ).notToHaveKey( "createdBy" );
			} );


			it( "can correctly do ignore defaults with nested includes", function(){
				var event = this.request(
					route  = "/",
					params = {
						ignoreDefaults : true,
						includes       : "fname,lname,settings,settings.latestValue"
					}
				);
				var memento = deserializeJSON( event.getRenderedContent() );
				expect( memento.settings ).toBeArray().notToBeEmpty();
				expect( memento.settings[ 1 ] )
					.toBeStruct()
					.toHaveKey( "latestValue" )
					.toHaveDeepKey( "description" );
			} );
		} );
	}

}
