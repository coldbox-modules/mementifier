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
				ormtype="string"
				setter="false";

	property 	name="permission"
				notnull="true"
				unique="true"
				length="255"
				default=""
				index="idx_permissionName";

	property 	name="description"
				notnull="false"
				default=""
				length="500"
				db_html="textarea";

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
		defaultIncludes : [ "permission", "description" ],
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