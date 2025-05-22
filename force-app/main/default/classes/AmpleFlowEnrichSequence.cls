public class AmpleFlowEnrichSequence {
    // DTO for Flow input
    public class AmpRequest {
        @InvocableVariable(required=true)
        public Id contactId;
        @InvocableVariable(required=true)
        public String apiKey;
        @InvocableVariable(required=true)
        public String sequenceId;
        @InvocableVariable(required=false)
        public Boolean ignore_recently_contacted = true;
        @InvocableVariable(required=false)
        public Boolean ignore_exclusion_list = true;
        @InvocableVariable(required=false)
        public Boolean ignore_duplicate_draft = true;
        @InvocableVariable(required=false)
        public Boolean ignore_duplicate_active = true;
    }

    // DTO for Flow output
    public class AmpResponse {
        @InvocableVariable
        public Boolean success;
        @InvocableVariable
        public String message;
    }

    // Enrichment data structure
    public class EnrichData {
        public String first_name;
        public String last_name;
        public String linkedin_url;
        public String title;
        public String company_name;
    }

    @InvocableMethod(label='Amplemarket: Enrich & Add to Sequence')
    public static List<AmpResponse> run(List<AmpRequest> requests) {
        List<AmpResponse> responses = new List<AmpResponse>();
        for (AmpRequest req : requests) {
            AmpResponse response = new AmpResponse();
            try {
                // Fetch Contact
                Contact contact = [SELECT Id, Email, FirstName, LastName FROM Contact WHERE Id = :req.contactId LIMIT 1];
                if (contact.Email == null) throw new Exception('Contact email is required');

                // Enrich via Amplemarket
                EnrichData enrichData = findPerson(contact.Email, req.apiKey);

                // Prepare data for sequence
                Map<String, String> data = new Map<String, String>{
                    'first_name' => enrichData.first_name,
                    'last_name' => enrichData.last_name,
                    'title' => enrichData.title,
                    'company_name' => enrichData.company_name
                };
                Map<String, Boolean> overrides = new Map<String, Boolean>{
                    'ignore_recently_contacted' => req.ignore_recently_contacted,
                    'ignore_exclusion_list' => req.ignore_exclusion_list,
                    'ignore_duplicate_leads_in_other_draft_sequences' => req.ignore_duplicate_draft,
                    'ignore_duplicate_leads_in_other_active_sequences' => req.ignore_duplicate_active
                };

                // Add to sequence
                HttpResponse seqRes = addToSequence(
                    req.sequenceId, contact.Email, enrichData.linkedin_url, data, overrides, req.apiKey
                );

                // Create Task (WhoId for Contact)
                Task t = new Task(
                    Subject = 'Added to Amplemarket sequence ' + req.sequenceId,
                    WhoId = contact.Id,
                    Status = 'Completed',
                    Description = 'Enrich status: Success | Sequence status: ' + String.valueOf(seqRes.getStatusCode())
                );
                insert t;

                response.success = true;
                response.message = 'Successfully enriched and added to sequence.';
            } catch (Exception e) {
                response.success = false;
                response.message = e.getMessage();
            }
            responses.add(response);
        }
        return responses;
    }

    // --- Service: Enrichment ---
    private static EnrichData findPerson(String email, String apiKey) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.amplemarket.com/people/find?email=' + EncodingUtil.urlEncode(email, 'UTF-8'));
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + apiKey);
        req.setHeader('accept', 'application/json');
        Http http = new Http();
        HttpResponse res = http.send(req);
        if (res.getStatusCode() == 200) {
            return (EnrichData)JSON.deserialize(res.getBody(), EnrichData.class);
        }
        throw new Exception('Enrichment failed with status: ' + res.getStatusCode() + ' - ' + res.getBody());
    }

    // --- Service: Sequence ---
    private static HttpResponse addToSequence(
        String sequenceId, String email, String linkedinUrl, Map<String, String> data,
        Map<String, Boolean> overrides, String apiKey
    ) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.amplemarket.com/sequences/' + sequenceId + '/leads');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + apiKey);
        req.setHeader('Content-Type', 'application/json');
        Map<String, Object> lead = new Map<String, Object>{
            'email' => email,
            'linkedin_url' => linkedinUrl,
            'data' => data,
            'overrides' => overrides
        };
        Map<String, Object> body = new Map<String, Object>{ 'leads' => new List<Object>{ lead } };
        req.setBody(JSON.serialize(body));
        Http http = new Http();
        return http.send(req);
    }
} 