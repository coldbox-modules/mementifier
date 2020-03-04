/**
 * A User
 */
component 	persistent="true"
			table="users"
			extends="BaseEntity"
			db_sortBy="lname"{

	/* *********************************************************************
	**						DI
	********************************************************************* */

	property 	name="userService"
				inject="entityService:User"
                persistent="false";

	/* *********************************************************************
	**						NON-PERSISTED PROPERTIES
	********************************************************************* */

	property 	name="loggedIn"
				persistent="false"
				default="false"
				type="boolean";

	property 	name="permissionList"
				persistent="false";

	property 	name="alreadySerialized"
				type="array"
				persistent="false";

	/* *********************************************************************
	**						PROPERTIES
	********************************************************************* */

	property 	name="userID"
				column="user_id"
				fieldtype="id"
				generator="uuid"
				ormtype="string";

	property 	name="fname"
				notnull="true";

	property 	name="lname"
				notnull="true";

	property 	name="email"
				unique="true"
				notnull="true"
				index="idx_email,idx_byEmail"
				db_display="false";

	property 	name="username"
				unique="true"
				notnull="true"
				index="idx_credentials";

	property 	name="password"
				notnull="true"
				db_display="false";

	property 	name="isConfirmed"
				ormtype="boolean"
				default="false"
				notnull="true"
				index="idx_byEmail,idx_confirmed,idx_credentials";

	property 	name="lastLogin"
				notnull="false"
				ormtype="timestamp"
				db_display="false";

	property 	name="facebookURL"
				notnull="false"
				db_display="false";

	property 	name="twitterURL"
				notnull="false"
				db_display="false";

	property 	name="blogURL"
				notnull="false"
				db_display="false";

	property 	name="otherURL"
				notnull="false"
				db_display="false";

	property 	name="linkedinURL"
				notnull="false"
				db_display="false";

	property 	name="githubURL"
				notnull="false"
				db_display="false";

	property 	name="APIToken"
				notnull="false"
				length="255"
				unique="true"
				index="idx_apitokens"
				default=""
				db_display="false";

	property 	name="addToMailingList"
				ormtype="boolean"
				default="false"
				notnull="true"
				index="idx_mailingList";

	/* *********************************************************************
	**						RELATIONSHIPS
	********************************************************************* */

	// M20 -> Role
	property 	name="role"
				notnull="true"
				fieldtype="many-to-one"
				cfc="Role"
				fkcolumn="FK_roleID"
				lazy="true"
				db_displayColumns="role";

	// M2M -> A-la-carte Author Permissions
	property 	name="permissions"
				singularName="permission"
				fieldtype="many-to-many"
				type="array"
				lazy="extra"
			  	cfc="Permission"
			 	cascade="all"
			  	fkcolumn="FK_userID"
			 	linktable="userPermissions"
			 	inversejoincolumn="FK_permissionID"
			 	orderby="permission"
			 	db_displayColumns="permission";

	/* *********************************************************************
	**						STATIC PROPERTIES & CONSTRAINTS
	********************************************************************* */

	// pk
	this.pk = "userID";

	// Mementofication Settings
	this.memento = {
		// Default properties to serialize
		defaultIncludes = [ "*" ],
		// Default Exclusions
		defaultExcludes = [
			"APIToken",
			"password",
			"role",
			"permissions"
		],
		neverInclude = [
			"password"
		],
		// Defaults
		defaults = {
			"role" = {}
		}
	};

	/**
	 * Constructor
	 */
	function init(){
		super.init();

		variables.isActive 			= true;
		variables.isConfirmed 		= false;
		variables.createdDate 		= now();
		variables.updatedDate 		= now();
		variables.loggedIn			= false;
		variables.permissions 		= [];
		variables.permissionList 	= "";
		variables.APIToken 			= "";
		variables.addToMailingList	= false;
		variables.alreadySerialized = [];

		// startup a token
		generateAPIToken();

		return this;
	}

	/**
	* Listen to postLoad's
	*/
	function postLoad(){
		// Verify if the user has already an API Token, else generate one for them.
		if( !len( getAPIToken() ) ){
			generateAPIToken();
		}
	}

	/**
	* Get the user's role name
	*/
	string function getRoleName(){
		return ( hasRole() ? getRole().getName() : '' );
	}

	/**
	* Generate new API Token, stores it locally but does not persist it.
	*/
	User function generateAPIToken(){
		variables.APIToken = hash( createUUID() & now(), "sha-512" );
		return this;
	}

	/**
	* Check for permission
	* @slug The permission slug or list of slugs to validate the user has. If it's a list then they are ORed together
	*/
	boolean function checkPermission( required slug ){
		// cache list
		if( !len( variables.permissionList ) AND hasPermission() ){
			var q = entityToQuery( getPermissions() );
			variables.permissionList = valueList( q.permission );
		}
		// checks via role and local
		if( getRole().checkPermission( arguments.slug ) OR inPermissionList( arguments.slug ) ){
			return true;
		}

		return false;
	}

	/**
	* Verify that a passed in list of perms the user can use
	*/
	boolean function inPermissionList( required list ){
		var aList 	= listToArray( arguments.list );
		var isFound = false;

		for( var thisPerm in aList ){
			if( listFindNoCase( permissionList, trim( thisPerm ) ) ){
				isFound = true;
				break;
			}
		}

		return isFound;
	}

	/**
	* Clear all permissions
	*/
	User function clearPermissions(){
		variables.permissions.clear();
		return this;
	}

	/**
	* Override the setPermissions
	*/
	User function setPermissions( required array permissions ){
		if( hasPermission() ){
			variables.permissions.clear();
			variables.permissions.addAll( arguments.permissions );
		} else {
			variables.permissions = arguments.permissions;
		}
		return this;
	}

	/**
	* Validate if a user is logged in or not
	*/
	boolean function isLoggedIn(){
		return variables.loggedIn;
	}

	/**
	* Is same user verification
	* @user The user ID or user object to validate equality
	*/
	function isSameUser( required user ){
		// check if numeric?
		if( isNumeric( arguments.user ) ){
			inID = arguments.user;
		} // else treat as object
		else{
			inID = arguments.user.getUserID();
        }
        param inID = 0;

		return ( compare( inID, getUserID() ) eq 0 );
	}

	/**
	* Retrieve full name
	*/
	string function getFullName(){
		return getFname() & " " & getlname();
	}

	/**
	 * Get the avatar link for this user.
	 */
	string function getAvatarLink( numeric size=40 ){
		return "//avatar.com?id=#createUUID()#";
	}
}
