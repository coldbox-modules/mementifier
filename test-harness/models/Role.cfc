/**
 * A Role
 */
component
	persistent="true"
	table     ="roles"
	db_sortBy ="role"
	extends   ="BaseEntity"
	cachename ="Role"
	cacheuse  ="read-write"
{

	/* *********************************************************************
	 **						PROPERTIES
	 ********************************************************************* */

	property
		name     ="roleID"
		column   ="role_id"
		fieldtype="id"
		generator="uuid"
		length   ="36"
		ormtype  ="string"
		setter   ="false";

	property
		name   ="role"
		notnull="true"
		unique ="true"
		ormtype="string"
		length ="255"
		default="";

	property
		name   ="description"
		column ="description"
		ormtype="string"
		notnull="false"
		default=""
		length ="500";

	/* *********************************************************************
	 **						RELATIONS
	 ********************************************************************* */

	// M2M -> Permissions
	property
		name             ="permissions"
		singularName     ="permission"
		fieldtype        ="many-to-many"
		type             ="array"
		lazy             ="true"
		orderby          ="permission"
		cascade          ="save-update"
		cacheuse         ="read-write"
		cfc              ="Permission"
		fkcolumn         ="FK_roleID"
		linktable        ="rolePermissions"
		inversejoincolumn="FK_permissionID"
		db_displayColumns="permission";

	/* *********************************************************************
	 **						CALCULATED PROPERTIES
	 ********************************************************************* */

	// Calculated Fields
	property
		name   ="numberOfPermissions"
		formula="select count(*) from rolePermissions as rolePermissions where rolePermissions.FK_roleID=role_id";

	property name="numberOfUsers" formula="select count(*) from users as users where users.FK_roleID=role_id";

	/* *********************************************************************
	 **						NON-PERSISTED PROPERTIES
	 ********************************************************************* */

	// Non-Persistable Fields
	property name="permissionList" persistent="false";

	/* *********************************************************************
	 **						PUBLIC PROPERTIES
	 ********************************************************************* */

	// PK
	this.pk = "roleID";

	// Mementofication
	this.memento = {
		defaultIncludes : [
			// "role",
			"description",
			"permissions"
		],
		defaultExcludes : []
	};

	/**
	 * Constructor
	 */
	function init(){
		variables.permissions    = [];
		variables.permissionList = "";

		return this;
	}

	/**
	 * Get the role name, same as getRole()
	 */
	string function getName(){
		return variables.role;
	}

	/**
	 * Check for permission
	 *
	 * @slug.hint The permission slug or list of slugs to validate the role has. If it's a list then they are ORed together
	 */
	boolean function checkPermission( required slug ){
		// cache list
		if ( !len( variables.permissionList ) AND hasPermission() ) {
			var q                    = entityToQuery( getPermissions() );
			variables.permissionList = valueList( q.permission );
		}

		// Do verification checks
		var aList   = listToArray( arguments.slug );
		var isFound = false;

		for ( var thisPerm in aList ) {
			if ( listFindNoCase( variables.permissionList, trim( thisPerm ) ) ) {
				isFound = true;
				break;
			}
		}

		return isFound;
	}

	/**
	 * Clear all permissions
	 */
	Role function clearPermissions(){
		variables.permissions = [];
		return this;
	}

	/**
	 * Override the setPermissions
	 */
	Role function setPermissions( required array permissions ){
		if ( hasPermission() ) {
			variables.permissions.clear();
			variables.permissions.addAll( arguments.permissions );
		} else {
			variables.permissions = arguments.permissions;
		}

		return this;
	}

}
