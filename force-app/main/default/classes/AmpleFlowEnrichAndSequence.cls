public class AmpleFlowEnrichAndSequence {

    // DTO for Flow input
    public class AmpRequest {
        @InvocableVariable(required=true)
        public String email;
        @InvocableVariable(required=true)
        public String amplemarket_api_key;
        @InvocableVariable(required=true)
        public String sequence_id;
        @InvocableVariable(required=false)
        public Boolean ignore_recently_contacted = false;
        @InvocableVariable(required=false)
        public Boolean ignore_exclusion_list = false;
        @InvocableVariable(required=false)
        public Boolean ignore_duplicate_draft = false;
        @InvocableVariable(required=false)
        public Boolean ignore_duplicate_active = false;
        @InvocableVariable(required=false)
        public String sequence_mailbox_email;
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
        public Company company;
    }

    // Company class
    public class Company {
        public String name;
        public String website;
        public String size;
        public String industry;
        public LocationDetails location_details;
    }

    // Location details class
    public class LocationDetails {
        public String city;
        public String state;
        public String country;
    }

    // Sequence API response structure
    public class SequenceResponseWrapper {
        public Integer total;
        public Integer total_added_to_sequence;
        public List<String> duplicate_emails;
        public List<String> duplicate_linkedin_urls;
        public List<SkippedLead> in_exclusion_list_and_skipped;
        public List<SkippedLead> recently_contacted_and_skipped;
        public List<SkippedLead> already_in_sequence_and_skipped;
        public List<SkippedLead> in_other_draft_sequences_and_skipped;
        public List<SkippedLead> in_other_active_sequences_and_skipped;
    }

    public class SkippedLead {
        public String email;
        public String linkedin_url;
    }

    // Custom exception for this class
    public class AmpleFlowException extends Exception {}


    @InvocableMethod(label='Amplemarket: Enrich & Add to Sequence')
    public static List<AmpResponse> run(List<AmpRequest> requests) {
        List<AmpResponse> responses = new List<AmpResponse>();
        for (AmpRequest req : requests) {
            AmpResponse response = new AmpResponse();
            try {
                if (req.email == null) throw new AmpleFlowException('Email is required');

                // Enrich via Amplemarket
                EnrichData enrichData = findPerson(req.email, req.amplemarket_api_key);

                // Extract company information
                String companyName = '';
                String companyWebsite = '';
                String companySize = '';
                String industry = '';
                String city = '';
                String state = '';
                String country = '';

                if (enrichData.company != null) {
                    companyName = enrichData.company.name;
                    companyWebsite = enrichData.company.website;
                    companySize = enrichData.company.size;
                    industry = enrichData.company.industry;

                    if (enrichData.company.location_details != null) {
                        city = enrichData.company.location_details.city;
                        state = enrichData.company.location_details.state;
                        country = enrichData.company.location_details.country;
                    }
                }

                // Prepare data for sequence
                Map<String, String> data = new Map<String, String>{
                    'first_name' => enrichData.first_name,
                    'last_name' => enrichData.last_name,
                    'title' => enrichData.title,
                    'company_name' => companyName,
                    'company_website' => companyWebsite,
                    'company_size' => companySize,
                    'industry' => industry,
                    'city' => city,
                    'state' => state,
                    'country' => country
                };
                // Build override map: treat included-but-empty (null) as true, not included as false
                Map<String, Boolean> overrides = new Map<String, Boolean>{
                    'ignore_recently_contacted' => req.ignore_recently_contacted == false ? false : true,
                    'ignore_exclusion_list' => req.ignore_exclusion_list == false ? false : true,
                    'ignore_duplicate_leads_in_other_draft_sequences' => req.ignore_duplicate_draft == false ? false : true,
                    'ignore_duplicate_leads_in_other_active_sequences' => req.ignore_duplicate_active == false ? false : true
                };

                // Add to sequence
                HttpResponse seqRes = addToSequence(
                    req.sequence_id, req.email, enrichData.linkedin_url, data, overrides, req.amplemarket_api_key, req.sequence_mailbox_email
                );

                // Parse sequence response
                SequenceResponseWrapper seqResponse = (SequenceResponseWrapper)JSON.deserialize(seqRes.getBody(), SequenceResponseWrapper.class);

                // Handle null values safely
                Integer totalAdded = seqResponse.total_added_to_sequence != null ? seqResponse.total_added_to_sequence : 0;
                if (totalAdded == 1) {
                    response.success = true;
                    response.message = 'Successfully enriched and added to sequence.';
                } else {
                    response.success = false;
                    response.message = 'Lead was not added to sequence. Enrichment succeeded but sequencing failed.';
                }
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
        throw new AmpleFlowException('Enrichment failed with status: ' + res.getStatusCode() + ' - ' + res.getBody());
    }

    // --- Service: Sequence ---
    private static HttpResponse addToSequence(
        String sequence_id, String email, String linkedinUrl, Map<String, String> data,
        Map<String, Boolean> overrides, String api_key, String mailbox_email
    ) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.amplemarket.com/sequences/' + sequence_id + '/leads');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + api_key);
        req.setHeader('Content-Type', 'application/json');

        Map<String, Object> lead = new Map<String, Object>{
            'email' => email,
            'linkedin_url' => linkedinUrl,
            'data' => data,
            'overrides' => overrides
        };

        Map<String, Object> body = new Map<String, Object>{ 'leads' => new List<Object>{ lead } };

        // Add settings if mailbox email is provided
        if (String.isNotBlank(mailbox_email)) {
            Map<String, Object> settings = new Map<String, Object>{
                'leads_distribution' => 'custom_mailboxes',
                'mailboxes' => new List<String>{ mailbox_email }
            };
            body.put('settings', settings);
        }

        req.setBody(JSON.serialize(body));
        Http http = new Http();
        HttpResponse res = http.send(req);
        if (res.getStatusCode() != 200) {
            throw new AmpleFlowException('Sequence API call failed with status: ' + res.getStatusCode() + ' - ' + res.getBody());
        }
        return res;
    }
}