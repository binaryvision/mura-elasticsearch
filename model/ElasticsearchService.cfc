component accessors=true {
    property name="beanFactory";

    this.DATE_FORMAT = "yyyy-MM-dd";
    this.DATETIME_FORMAT = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";

    dateFormatter = createObject("java", "java.text.SimpleDateFormat").init(this.DATE_FORMAT);
    datetimeFormatter = createObject("java", "java.text.SimpleDateFormat").init(this.DATETIME_FORMAT);

    function parseDate(required datetimeString) {
        return dateFormatter.parse(datetimeString);
    }

    function parseDatetime(required datetimeString) {
        return datetimeFormatter.parse(datetimeString);
    }

    function formatDate(required datetime) {
        return dateFormatter.format(datetime);
    }

    function formatDatetime(required datetime) {
        return datetimeFormatter.format(datetime);
    }

    function getClient(required host) {
        if(not structKeyExists(structGet("variables.clients"), host))
            variables.clients[host] = getBeanFactory().getBean("ElasticsearchClient").setHost(host);
        return variables.clients[host];
    }

}