component accessors=true {
    elasticsearchDateFormat = "yyyyMMdd";
    elasticsearchDatetimeFormat = "yyyyMMdd'T'HHmmss.SSSZ";

    function formatDate(required date) {
        return getDateFormatter().format(date);
    }

    function formatDatetime(required datetime) {
        return getDatetimeFormatter().format(datetime);
    }

    function getDateFormatter() {
        return createObject("java", "java.text.SimpleDateFormat").init(elasticsearchDateFormat);
    }

    function getDatetimeFormatter() {
        return createObject("java", "java.text.SimpleDateFormat").init(elasticsearchDatetimeFormat);
    }

}