/**
 * This is the base class for all persistent entities
 */
component mappedsuperclass="true" accessors="true"{

	/* *********************************************************************
	**							PROPERTIES
	********************************************************************* */

	property 	name="createdDate"
				type="date"
				ormtype="timestamp"
				notnull="true"
				update="false";

	property 	name="updatedDate"
				type="date"
				ormtype="timestamp"
				notnull="true";

	property 	name="isActive"
				ormtype="boolean"
				default="true"
				notnull="true";

	/* *********************************************************************
	**						PUBLIC FUNCTIONS
	********************************************************************* */

	/**
	* Constructor
	*/
	BaseEntity function init(){
		variables.createdDate 	= now();
		variables.updatedDate 	= now();
		variables.isActive		= true;

		return this;
	}

	/*
	* pre insertion procedures
	*/
	void function preInsert(){
		var now = now();
		variables.createdDate 	= now;
		variables.updatedDate 	= now;
	}

	/*
	* pre update procedures
	*/
	void function preUpdate( struct oldData ){
		variables.updatedDate 	= now();
	}

	/**
	* Verify if entity is loaded or not
	*/
	boolean function isLoaded(){
		return ( isNull( variables[ this.pk ] ) OR !len( variables[ this.pk ] ) ? false : true );
	}

}
