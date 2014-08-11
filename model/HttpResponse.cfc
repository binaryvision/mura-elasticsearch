component accessors=true {
    property name="response";

    function isJSON() {
        if(not isDefined("responseIsJSON"))
            responseIsJSON = isJSON(getResponse().fileContent);

        return responseIsJSON;
    }

    function toJSON() {
        if (not isDefined("responseJSON") and this.isJSON())
            responseJSON = deserializeJSON(getResponse().fileContent);

        return responseJSON;
    }

    function toString() {
        return getResponse().fileContent;
    }

    function getStatusCode() {
        return val(getResponse().statusCode);
    }

    function is404() {
        return getStatusCode() eq 404;
    }

    function is200() {
        return getStatusCode() eq 200;
    }

}