component accessors=true {
    property name="beanFactory";

    function request(
        required string method,
        required string url,
        any body,
        array auth,
        struct params={},
        struct headers={}
    ) {
        var http = new http(
            url = arguments.url,
            method = arguments.method
        );

        if (isDefined("arguments.auth")) {
            http.setUsername(auth[1]);
            http.setPassword(auth[2]);
        }

        if (isDefined("arguments.body") and (not isSimpleValue(arguments.body) or len(arguments.body))) {
            if (not structKeyExists(headers, "Content-Type")) {
                if (isStruct(body) or isJson(body))
                    http.addParam(type="header", name="Content-Type", value="application/json");
                else if (isXml(body))
                    http.addParam(type="header", name="Content-Type", value="application/xml; charset=UTF-8");
            }

            http.addParam(type="body", value=(isStruct(body) ? serializeJSON(body) : body));
        }

        for (var key in params)
            http.addParam(type="url", name=key, value=params[key]);
        for (var key in headers)
            http.addParam(type="headers", name=key, value=headers[key]);

        return getBeanFactory().getBean("httpResponse").setResponse(http.send().getPrefix());
    }

    function get() {
        return request(method="get", argumentCollection=arguments);
    }

    function put() {
        return request(method="put", argumentCollection=arguments);
    }

    function post() {
        return request(method="post", argumentCollection=arguments);
    }

}