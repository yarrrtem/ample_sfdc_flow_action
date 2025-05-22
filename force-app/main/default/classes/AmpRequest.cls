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