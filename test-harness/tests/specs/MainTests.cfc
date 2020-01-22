component extends="coldbox.system.testing.BaseTestCase"{

/*********************************** BDD SUITES ***********************************/

	function run(){

		describe( "Mementifier", function(){

			beforeEach(function( currentSpec ){
				setup();
			});

			it( "can render base mementos", function(){
				var event = this.request( route="/main/index", params={} );
				var memento = deserializeJSON( event.getRenderedContent() );
				// Derfault INcludes + Excludes
				expect( memento )
					.toBeStruct()
					.notToHaveKey( "role" )
					.notToHaveKey( "permission" );
				// mapper
				expect( memento.lname ).toBe( "TESTUSER" );
			});

			it( "can render mementos even if the obejct has already-serialized data", function(){
				var event = this.request( route="/main/alreadySerialized", params={} );
				var memento = deserializeJSON( event.getRenderedContent() );
				// Derfault INcludes + Excludes

				expect( memento[ "alreadySerialized" ] )
					.toBeArray()
					.toHaveLength( 2 );

				expect( memento [ "alreadySerialized" ][ 1 ] )
					.toBeStruct()
					.toHaveKey( 'foo' );

				expect( memento [ "alreadySerialized" ][ 2 ] )
					.toBeStruct()
					.toHaveKey( 'baz' );

				expect( memento[ "alreadySerialized" ][ 1 ][ 'foo' ] )
					.toBe( 'bar' );
			});


			it( "can process a resultsMap", function(){
				var results = this.request( route="/main/resultMap" )
					.getValue( "cbox_handler_results" );

				expect( results ).toHaveKey( "results" ).toHaveKey( "resultsMap" );
				expect( results.resultsMap ).toHaveKey( results.results[ 1 ] );
            });


            it( "can render inherited properties with wildcard default properties", function() {

                var event = this.request(
                    route="/main/index",
                    params={ }
                );

				var memento = deserializeJSON( event.getRenderedContent() );

                // Expect inherited properties from the base class
				expect( memento )
					.toBeStruct()
					.toHaveKey( "createdDate,isActive" )
					.notToHaveKey( "modifiedDate" );

            } );


		});

	}

}