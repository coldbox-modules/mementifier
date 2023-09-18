/**
 * A test one-to-one
 */
component
	persistent="true"
	table     ="recentvalues"
	extends   ="BaseEntity"
{

	/* *********************************************************************
	 **						PROPERTIES
	 ********************************************************************* */

	property
		name     ="recentValueId"
		column   ="recentValueId"
		fieldtype="id"
		generator="uuid"
		length   ="36"
		ormtype  ="string"
		setter   ="false";

	property
		name   ="description"
		column ="description"
		ormtype="string"
		notnull="false"
		default=""
		length ="500";


	/* *********************************************************************
	 **							PK + CONSTRAINTS
	 ********************************************************************* */

	// pk
	this.pk = "recentValueId";

	// Mementofication
	this.memento = {
		defaultIncludes : [ "description" ],
		defaultExcludes : []
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
