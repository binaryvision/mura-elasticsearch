component accessors=true {
    property name="response";

    function init(required response) {
        setResponse(response);
        return this;
    }

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

    function getStatusCode() {
        return val(getResponse().statusCode);
    }

}