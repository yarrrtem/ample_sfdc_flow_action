@isTest
private class AmpleFlowEnrichAndSequenceTest {
    @TestSetup
    static void setupTestData() {
        // Create test contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com'
        );
        insert testContact;
    }

    @isTest
    static void testSuccessfulEnrichAndSequence() {
        // Setup mock responses
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(
            '{"first_name":"Test","last_name":"Contact","linkedin_url":"https://linkedin.com/in/test","title":"Test Title","company":{"name":"Test Company","website":"https://test.com","size":"51-200","industry":"Technology","location_details":{"city":"San Francisco","state":"CA","country":"United States"}}}',
            '{"total":1,"total_added_to_sequence":1,"duplicate_emails":[],"duplicate_linkedin_urls":[],"in_exclusion_list_and_skipped":[],"recently_contacted_and_skipped":[],"already_in_sequence_and_skipped":[],"in_other_draft_sequences_and_skipped":[],"in_other_active_sequences_and_skipped":[]}'
        ));

        // Create request
        AmpleFlowEnrichAndSequence.AmpRequest req = new AmpleFlowEnrichAndSequence.AmpRequest();
        req.email = 'test@example.com';
        req.amplemarketApiKey = 'test-api-key';
        req.sequenceId = 'test-sequence-id';

        Test.startTest();
        List<AmpleFlowEnrichAndSequence.AmpResponse> responses = AmpleFlowEnrichAndSequence.run(new List<AmpleFlowEnrichAndSequence.AmpRequest>{req});
        Test.stopTest();

        // Verify response
        System.assertEquals(1, responses.size(), 'Should have one response');
        System.assertEquals(true, responses[0].success, 'Operation should be successful');
        System.assertEquals('Successfully enriched and added to sequence.', responses[0].message, 'Should have success message');
    }

    @isTest
    static void testFailedSequence() {
        // Setup mock responses
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(
            '{"first_name":"Test","last_name":"Contact","linkedin_url":"https://linkedin.com/in/test","title":"Test Title","company":{"name":"Test Company","website":"https://test.com","size":"51-200","industry":"Technology","location_details":{"city":"San Francisco","state":"CA","country":"United States"}}}',
            '{"total":1,"total_added_to_sequence":0,"duplicate_emails":[],"duplicate_linkedin_urls":[],"in_exclusion_list_and_skipped":[],"recently_contacted_and_skipped":[],"already_in_sequence_and_skipped":[],"in_other_draft_sequences_and_skipped":[],"in_other_active_sequences_and_skipped":[]}'
        ));

        // Create request
        AmpleFlowEnrichAndSequence.AmpRequest req = new AmpleFlowEnrichAndSequence.AmpRequest();
        req.email = 'test@example.com';
        req.amplemarketApiKey = 'test-api-key';
        req.sequenceId = 'test-sequence-id';

        Test.startTest();
        List<AmpleFlowEnrichAndSequence.AmpResponse> responses = AmpleFlowEnrichAndSequence.run(new List<AmpleFlowEnrichAndSequence.AmpRequest>{req});
        Test.stopTest();

        // Verify response
        System.assertEquals(1, responses.size(), 'Should have one response');
        System.assertEquals(false, responses[0].success, 'Operation should not be successful');
        System.assertEquals('Lead was not added to sequence. Enrichment succeeded but sequencing failed.', responses[0].message, 'Should have failure message');
    }

    @isTest
    static void testMissingEmail() {
        // Prepare test request
        AmpleFlowEnrichAndSequence.AmpRequest req = new AmpleFlowEnrichAndSequence.AmpRequest();
        req.email = null;
        req.amplemarketApiKey = 'test-api-key';
        req.sequenceId = 'test-sequence-id';
        
        Test.startTest();
        List<AmpleFlowEnrichAndSequence.AmpResponse> responses = AmpleFlowEnrichAndSequence.run(new List<AmpleFlowEnrichAndSequence.AmpRequest>{req});
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, responses.size(), 'Should return one response');
        System.assertEquals(false, responses[0].success, 'Should fail');
        System.assertEquals('Email is required', responses[0].message);
    }

    @isTest
    static void testEnrichmentFailure() {
        // Prepare test request
        AmpleFlowEnrichAndSequence.AmpRequest req = new AmpleFlowEnrichAndSequence.AmpRequest();
        req.email = 'test@example.com';
        req.amplemarketApiKey = 'invalid-api-key';
        req.sequenceId = 'test-sequence-id';
        
        // Mock HTTP callout to simulate enrichment failure
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(
            '{"error": "Bad Request"}',
            '{"total":0,"total_added_to_sequence":0,"duplicate_emails":[],"duplicate_linkedin_urls":[],"in_exclusion_list_and_skipped":[],"recently_contacted_and_skipped":[],"already_in_sequence_and_skipped":[],"in_other_draft_sequences_and_skipped":[],"in_other_active_sequences_and_skipped":[]}',
            true
        ));
        
        Test.startTest();
        List<AmpleFlowEnrichAndSequence.AmpResponse> responses = AmpleFlowEnrichAndSequence.run(new List<AmpleFlowEnrichAndSequence.AmpRequest>{req});
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, responses.size(), 'Should return one response');
        System.assertEquals(false, responses[0].success, 'Should fail');
        System.assert(responses[0].message.contains('Enrichment failed'), 'Should indicate enrichment failure');
    }

    @isTest
    static void testOverrideFlags() {
        // Prepare test request with override flags
        AmpleFlowEnrichAndSequence.AmpRequest req = new AmpleFlowEnrichAndSequence.AmpRequest();
        req.email = 'test@example.com';
        req.amplemarketApiKey = 'test-api-key';
        req.sequenceId = 'test-sequence-id';
        req.ignore_recently_contacted = true;
        req.ignore_exclusion_list = true;
        req.ignore_duplicate_draft = true;
        req.ignore_duplicate_active = true;
        
        // Mock HTTP callouts
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(
            '{"first_name":"Test","last_name":"Contact","linkedin_url":"https://linkedin.com/in/test","title":"Test Title","company":{"name":"Test Company","website":"https://test.com","size":"51-200","industry":"Technology","location_details":{"city":"San Francisco","state":"CA","country":"United States"}}}',
            '{"total":1,"total_added_to_sequence":1,"duplicate_emails":[],"duplicate_linkedin_urls":[],"in_exclusion_list_and_skipped":[],"recently_contacted_and_skipped":[],"already_in_sequence_and_skipped":[],"in_other_draft_sequences_and_skipped":[],"in_other_active_sequences_and_skipped":[]}'
        ));
        
        Test.startTest();
        List<AmpleFlowEnrichAndSequence.AmpResponse> responses = AmpleFlowEnrichAndSequence.run(new List<AmpleFlowEnrichAndSequence.AmpRequest>{req});
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, responses.size(), 'Should return one response');
        System.assertEquals(true, responses[0].success, 'Should be successful');
    }

    @isTest
    static void testMissingCompanyData() {
        // Prepare test request
        AmpleFlowEnrichAndSequence.AmpRequest req = new AmpleFlowEnrichAndSequence.AmpRequest();
        req.email = 'test@example.com';
        req.amplemarketApiKey = 'test-api-key';
        req.sequenceId = 'test-sequence-id';
        
        // Mock HTTP callout with missing company data
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(
            '{"first_name":"Test","last_name":"Contact","linkedin_url":"https://linkedin.com/in/test","title":"Test Title"}',
            '{"total":1,"total_added_to_sequence":1,"duplicate_emails":[],"duplicate_linkedin_urls":[],"in_exclusion_list_and_skipped":[],"recently_contacted_and_skipped":[],"already_in_sequence_and_skipped":[],"in_other_draft_sequences_and_skipped":[],"in_other_active_sequences_and_skipped":[]}'
        ));
        
        Test.startTest();
        List<AmpleFlowEnrichAndSequence.AmpResponse> responses = AmpleFlowEnrichAndSequence.run(new List<AmpleFlowEnrichAndSequence.AmpRequest>{req});
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, responses.size(), 'Should return one response');
        System.assertEquals(true, responses[0].success, 'Should be successful even with missing company data');
    }

    // Mock HTTP Response Generator
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private String enrichResponse;
        private String sequenceResponse;
        private Boolean shouldFail;
        private Integer callCount = 0;

        public MockHttpResponseGenerator(String enrichResponse, String sequenceResponse) {
            this.enrichResponse = enrichResponse;
            this.sequenceResponse = sequenceResponse;
            this.shouldFail = false;
        }

        public MockHttpResponseGenerator(String enrichResponse, String sequenceResponse, Boolean shouldFail) {
            this.enrichResponse = enrichResponse;
            this.sequenceResponse = sequenceResponse;
            this.shouldFail = shouldFail;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            // First call is enrichment, second is sequence
            if (callCount == 0) {
                res.setBody(enrichResponse);
                res.setStatusCode(shouldFail ? 400 : 200);
            } else {
                res.setBody(sequenceResponse);
                res.setStatusCode(200);
            }
            
            callCount++;
            return res;
        }
    }
} 