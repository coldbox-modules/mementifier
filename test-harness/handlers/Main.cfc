component{

	property name="userService" inject="entityService:User";
	property name="roleService" inject="entityService:Role";
	property name="permissionService" inject="entityService:Permission";

	function index( event, rc, prc ){
		param rc.ignoreDefaults = false;
		param rc.includes = "";
		param rc.excludes = "";

		var mockData = {
			fname = "testuser",
			lname = "testuser",
			email = "testuser@testuser.com",
			username = "testuser",
			isConfirmed = true,
			isActive = true,
			otherURL = "www.luismajano.com"
		};

		var oUser = populateModel(
			model					= userService.new(),
			memento 				= mockData,
			composeRelationships	= true
		);
		oUser.setRole(
			roleService.new( {
				role="Admin",
				description="Awesome Admin"
			} )
		);
		oUser.getRole().setPermissions( [
			permissionService.new( { permission="READ", description="read" } ),
			permissionService.new( { permission="WRITE", description="write" } )
		] );
		oUser.setPermissions( [
			permissionService.new( { permission="CUSTOM_READ", description="read" } ),
			permissionService.new( { permission="CUSTOM_WRITE", description="write" } )
		] );

		return oUser.getMemento(
			includes        = rc.includes,
			excludes        = rc.excludes,
			ignoreDefaults 	= rc.ignoreDefaults,
			mappers = {
				lname = function( item ){ return item.ucase(); }
			}
		);
	}

}