component accessors=true {
    property name="response";

    function isJSON() {
        return isJSON(getResponse().fileContent);
    }

    function toJSON() {
        return this.isJSON() ? deserializeJSON(getResponse().fileContent) : getResponse().fileContent;
    }

    function toString() {
        return getResponse().fileContent;
    }

    function getStatusCode() {
        return val(getResponse().statusCode);
    }

    function getStatusCodeString() {
        return getResponse().statusCode;
    }

    function is404() {
        return getStatusCode() eq 404;
    }

    function is200() {
        return getStatusCode() eq 200;
    }

}