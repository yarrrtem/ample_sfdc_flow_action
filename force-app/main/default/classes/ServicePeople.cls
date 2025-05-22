public class ServicePeople {
    private static final String BASE_URL = 'https://api.amplemarket.com';
    private static final String ENDPOINT = '/people/find';
    
    public class EnrichData {
        public String first_name;
        public String last_name;
        public String linkedin_url;
        public String title;
        public String company_name;
    }
    
    public static EnrichData findPerson(String email, String apiKey) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(BASE_URL + ENDPOINT + '?email=' + EncodingUtil.urlEncode(email, 'UTF-8'));
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + apiKey);
        req.setHeader('accept', 'application/json');
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            return (EnrichData)JSON.deserialize(res.getBody(), EnrichData.class);
        }
        
        throw new AmpException('Enrichment failed with status: ' + res.getStatusCode() + ' - ' + res.getBody());
    }
    
    public class AmpException extends Exception {}
} 