/**
 * A Permission
 */
component 	persistent="true"
			table="permissions"
			extends="BaseEntity"
			cachename="Permission"
			cacheuse="read-write"
{

	/* *********************************************************************
	**						PROPERTIES
	********************************************************************* */

	property 	name="permissionID"
				column="permission_id"
				fieldtype="id"
				generator="uuid"
				length   ="36"
				ormtype="string"
				setter="false";

	property 	name="permission"
				notnull="true"
				ormtype="string"
				unique="true"
				length="255"
				default="";

	property
				name   ="description"
				column ="description"
				ormtype="string"
				notnull="false"
				default=""
				length ="500";

	/* *********************************************************************
	**							CALCULATED FIELDS
	********************************************************************* */

	// Calculated Fields
	property 	name="numberOfRoles"
				formula="select count(*) from rolePermissions as rolePermissions
						where rolePermissions.FK_permissionID=permission_id";

	/* *********************************************************************
	**							PK + CONSTRAINTS
	********************************************************************* */

	// pk
	this.pk = "permissionID";

	// Mementofication
	this.memento = {
		defaultIncludes : [
			//"permission",
			"description"
		],
		defaultExcludes : [ ]
	};

	/* *********************************************************************
	**							PUBLIC FUNCITONS
	********************************************************************* */

	/**
	* Constructor
	*/
	function init(){
		super.init();
		return this;
	}

}
