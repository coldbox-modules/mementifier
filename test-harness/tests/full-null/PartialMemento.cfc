component accessors="true" {

	property name="id";

	this.memento = { defaultIncludes : [ "id" ] };

	function init(){
		variables.id = "partial-memento";
		return this;
	}

}
