public class AmpOrchestrator {
    @InvocableMethod(label='Enrich & Add to Sequence' description='Enriches contact data and adds to Amplemarket sequence')
    public static List<AmpResponse> run(List<AmpRequest> requests) {
        List<AmpResponse> responses = new List<AmpResponse>();
        
        for (AmpRequest req : requests) {
            AmpResponse response = new AmpResponse();
            try {
                // Fetch contact
                Contact contact = [SELECT Id, Email, FirstName, LastName, Account.Website 
                                 FROM Contact 
                                 WHERE Id = :req.contactId 
                                 LIMIT 1];
                
                if (contact.Email == null) {
                    throw new AmpException('Contact email is required');
                }
                
                // Enrich data
                ServicePeople.EnrichData enrichData = ServicePeople.findPerson(contact.Email, req.apiKey);
                
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
                HttpResponse seqResponse = ServiceSequence.addToSequence(
                    req.sequenceId,
                    contact.Email,
                    enrichData.linkedin_url,
                    data,
                    overrides,
                    req.apiKey
                );
                
                // Create task
                ActivityService.createSequenceTask(
                    contact.Id,
                    req.sequenceId,
                    'Success',
                    String.valueOf(seqResponse.getStatusCode())
                );
                
                response.success = true;
                response.message = 'Successfully added to sequence';
                
            } catch (Exception e) {
                response.success = false;
                response.message = e.getMessage();
            }
            
            responses.add(response);
        }
        
        return responses;
    }
    
    public class AmpException extends Exception {}
} 