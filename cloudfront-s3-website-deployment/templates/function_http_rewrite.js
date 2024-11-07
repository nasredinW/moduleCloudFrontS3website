function handler(event) {
    var request = event.request;
    var host = request.headers.host.value;
    var uri = request.uri;
    var cnameTarget = '${cname_target}';
    if (uri.endsWith('/')) {
        request.uri +='index.html';
    }
    if (host.includes('.cloudfront.net')){
        return {
            statusCode: 301, // Permanent redirect
            statusDescription: 'Moved Permanently',
            headers: {
                'cloudfront-functions': { value: 'generated-by-CloudFront-Functions' },
                'location': { value: 'https://'+cnameTarget }
            }
        };
    }

    return request;
}
