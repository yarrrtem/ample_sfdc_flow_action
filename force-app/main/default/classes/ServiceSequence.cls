public class ServiceSequence {
    private static final String BASE_URL = 'https://api.amplemarket.com';
    
    public class SequenceRequest {
        public List<LeadData> leads;
    }
    
    public class LeadData {
        public String email;
        public String linkedin_url;
        public Map<String, String> data;
        public Map<String, Boolean> overrides;
    }
    
    public static HttpResponse addToSequence(String sequenceId, String email, String linkedinUrl, 
                                           Map<String, String> data, Map<String, Boolean> overrides, 
                                           String apiKey) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(BASE_URL + '/sequences/' + sequenceId + '/leads');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + apiKey);
        req.setHeader('Content-Type', 'application/json');
        
        LeadData lead = new LeadData();
        lead.email = email;
        lead.linkedin_url = linkedinUrl;
        lead.data = data;
        lead.overrides = overrides;
        
        SequenceRequest seqReq = new SequenceRequest();
        seqReq.leads = new List<LeadData>{lead};
        
        req.setBody(JSON.serialize(seqReq));
        
        Http http = new Http();
        return http.send(req);
    }
} 