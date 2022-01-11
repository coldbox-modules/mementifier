component {

	property name="userService"       inject="entityService:User";
	property name="roleService"       inject="entityService:Role";
	property name="settingService"    inject="entityService:Setting";
	property name="permissionService" inject="entityService:Permission";

	function index( event, rc, prc ){
		param rc.ignoreDefaults = false;
		param rc.ignoredRoots   = "";
		param rc.includes       = "";
		param rc.excludes       = "";

		var mockData = {
			fname       : "testuser",
			lname       : "testuser",
			email       : "testuser@testuser.com",
			username    : "testuser",
			isConfirmed : true,
			isActive    : true,
			otherURL    : "www.luismajano.com"
		};

		var oUser = populateModel(
			model                = userService.new(),
			memento              = mockData,
			composeRelationships = true
		);
		oUser.setRole( roleService.new( { role : "Admin", description : "Awesome Admin" } ) );
		oUser
			.getRole()
			.setPermissions( [
				permissionService.new( { permission : "READ", description : "read" } ),
				permissionService.new( { permission : "WRITE", description : "write" } )
			] );
		oUser.setPermissions( [
			permissionService.new( { permission : "CUSTOM_READ", description : "read" } ),
			permissionService.new( { permission : "CUSTOM_WRITE", description : "write" } )
		] );

		oUser.setSettings( [
			getNewSetting(),
			getNewSetting(),
			getNewSetting(),
			getNewSetting(),
			getNewSetting()
		] );

		var result = oUser.getMemento(
			includes       = rc.includes,
			excludes       = rc.excludes,
			ignoreDefaults = rc.ignoreDefaults,
			ignoredRoots   = rc.ignoredRoots,
			trustedGetters = event.valueExists( "trustedGetters" ) ? rc.trustedGetters : javacast( "null", "" ),
			mappers        = {
				lname : function( item ){
					return item.ucase();
				},
				"foo" : function( _, memento ){
					return memento.firstName & " " & memento.lastName;
				}
			},
			iso8601Format = event.valueExists( "iso8601Format" ) ? rc.iso8601Format : javacast( "null", "" ),
			dateMask      = event.valueExists( "dateMask" ) ? rc.dateMask : javacast( "null", "" ),
			timeMask      = event.valueExists( "timeMask" ) ? rc.timeMask : javacast( "null", "" )
		);

		return result;
	}

	function nested( event, rc, prc ){
		var mockData = {
			fname       : "testuser",
			lname       : "testuser",
			email       : "testuser@testuser.com",
			username    : "testuser",
			isConfirmed : true,
			isActive    : true,
			otherURL    : "www.luismajano.com"
		};

		var oUser = populateModel(
			model                = userService.new(),
			memento              = mockData,
			composeRelationships = true
		);
		oUser.setRole( roleService.new( { role : "Admin", description : "Awesome Admin" } ) );
		oUser
			.getRole()
			.setPermissions( [
				permissionService.new( { permission : "READ", description : "read" } ),
				permissionService.new( { permission : "WRITE", description : "write" } )
			] );
		oUser.setPermissions( [
			permissionService.new( { permission : "CUSTOM_READ", description : "read" } ),
			permissionService.new( { permission : "CUSTOM_WRITE", description : "write" } )
		] );

		oUser.setSettings( [
			getNewSetting(),
			getNewSetting(),
			getNewSetting(),
			getNewSetting(),
			getNewSetting()
		] );

		var result = oUser.getMemento(
			includes = [ "role.permissions", "role.userId" ],
			mappers  = {
				"description" : function( item, memento ){
					throw( "Should not be called" );
				},
				"role.permissions.description" : function( item ){
					return uCase( item );
				}
			}
		);

		return result;
	}

	private function getNewSetting(){
		return settingService.new( {
			name        : "setting-#createUUID()#",
			description : "Hola!!!",
			isConfirmed : randRange( 0, 1 )
		} );
	}

	function resultMap( event, rc, prc ){
		// mock 10 users
		var aObjects = getInstance( "MockData@mockdatacfc" )
			.mock(
				userID      = "uuid",
				fname       = "fname",
				lname       = "lname",
				email       = "email",
				username    = "words",
				isConfirmed = "oneof:true:false",
				isActive    = "oneof:true:false",
				otherURL    = "words"
			)
			// Build out objects
			.map( function( item ){
				return populateModel(
					model                = userService.new(),
					memento              = item,
					composeRelationships = true
				);
			} );

		return getInstance( "ResultsMapper@mementifier" ).process( aObjects, "userId" );
	}

	function alreadySerialized( event, rc, prc ){
		param rc.ignoreDefaults = false;
		param rc.includes       = "";
		param rc.excludes       = "";

		var mockData = {
			fname             : "testuser",
			lname             : "testuser",
			email             : "testuser@testuser.com",
			username          : "testuser",
			isConfirmed       : true,
			isActive          : true,
			otherURL          : "www.luismajano.com",
			alreadySerialized : [ { "foo" : "bar" }, { "baz" : "frobozz" } ]
		};

		var oUser = populateModel(
			model                = userService.new(),
			memento              = mockData,
			composeRelationships = true
		);

		return oUser.getMemento(
			includes       = rc.includes,
			excludes       = rc.excludes,
			ignoreDefaults = rc.ignoreDefaults,
			mappers        = {}
		);
	}

}
