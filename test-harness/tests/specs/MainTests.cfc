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


		});

	}

}