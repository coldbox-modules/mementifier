/**
 * A Post
 */
component 	persistent="true"
			table="posts"
			extends="BaseEntity"{


	/* *********************************************************************
	**						PROPERTIES
	********************************************************************* */

	property 	name="postId"
				fieldtype="id"
				generator="uuid"
				length   ="36"
				ormtype="string";

	property 	name="slug"
				notnull="true"
				unique="true"
				sqltype="varchar(255)";

	property 	name="title"
				notnull="true";

	property 	name="teaser"
				default=""
				notnull="false";

	property 	name="body"
				default=""
				notnull="false";

	property 	name="isPublished"
				ormtype="boolean"
				default="false"
				notnull="false";

	property 	name="createdBy"
				fieldtype="many-to-one"
				lazy="true"
				update="false"
			  	cfc="User"
			  	fkcolumn="FK_creationUser";

	/* *********************************************************************
	**						STATIC PROPERTIES & CONSTRAINTS
	********************************************************************* */

	// pk
	this.pk = "postId";

	// Test default mementification settings

	/**
	 * Constructor
	 */
	function init(){
		super.init();
		return this;
	}

}