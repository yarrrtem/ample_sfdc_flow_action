@isTest
public class AmpMock implements HttpCalloutMock {
    private static final String SAMPLE_ENRICH_RESPONSE = '{"first_name":"Jonh","last_name":"Doe","linkedin_url":"https://www.linkedin.com/in/person-1","title":"Founder and CEO","company_name":"A Company"}';
    private static final String SAMPLE_SEQUENCE_RESPONSE = '{"total_added_to_sequence":1}';
    
    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        
        if (req.getEndpoint().contains('/people/find')) {
            res.setStatusCode(200);
            res.setBody(SAMPLE_ENRICH_RESPONSE);
        } else if (req.getEndpoint().contains('/sequences/') && req.getEndpoint().contains('/leads')) {
            res.setStatusCode(200);
            res.setBody(SAMPLE_SEQUENCE_RESPONSE);
        } else {
            res.setStatusCode(404);
            res.setBody('Not Found');
        }
        
        return res;
    }
} 