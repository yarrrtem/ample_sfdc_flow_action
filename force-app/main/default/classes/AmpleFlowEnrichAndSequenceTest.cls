@isTest
private class AmpleFlowEnrichAndSequenceTest {
    @TestSetup
    static void setupTestData() {
        // Create test contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test@example.com'
        );
        insert testContact;
    }

    @isTest
    static void testSuccessfulEnrichAndSequence() {
        // Get test contact
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'test@example.com' LIMIT 1];
        
        // Prepare test request
        AmpleFlowEnrichAndSequence.AmpRequest req = new AmpleFlowEnrichAndSequence.AmpRequest();
        req.contactId = testContact.Id;
        req.apiKey = 'test-api-key';
        req.sequenceId = 'test-sequence-id';
        
        // Mock HTTP callouts
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        List<AmpleFlowEnrichAndSequence.AmpResponse> responses = AmpleFlowEnrichAndSequence.run(new List<AmpleFlowEnrichAndSequence.AmpRequest>{req});
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, responses.size(), 'Should return one response');
        System.assertEquals(true, responses[0].success, 'Should be successful');
        System.assertEquals('Successfully enriched and added to sequence.', responses[0].message);
        
        // Verify task was created
        List<Task> tasks = [SELECT Id, Subject, Description FROM Task WHERE WhoId = :testContact.Id];
        System.assertEquals(1, tasks.size(), 'Should create one task');
        System.assert(tasks[0].Subject.contains('Added to Amplemarket sequence'), 'Task subject should mention sequence');
    }

    @isTest
    static void testMissingEmail() {
        // Create contact without email
        Contact testContact = new Contact(
            FirstName = 'No',
            LastName = 'Email'
        );
        insert testContact;
        
        // Prepare test request
        AmpleFlowEnrichAndSequence.AmpRequest req = new AmpleFlowEnrichAndSequence.AmpRequest();
        req.contactId = testContact.Id;
        req.apiKey = 'test-api-key';
        req.sequenceId = 'test-sequence-id';
        
        Test.startTest();
        List<AmpleFlowEnrichAndSequence.AmpResponse> responses = AmpleFlowEnrichAndSequence.run(new List<AmpleFlowEnrichAndSequence.AmpRequest>{req});
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, responses.size(), 'Should return one response');
        System.assertEquals(false, responses[0].success, 'Should fail');
        System.assertEquals('Contact email is required', responses[0].message);
    }

    @isTest
    static void testEnrichmentFailure() {
        // Get test contact
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'test@example.com' LIMIT 1];
        
        // Prepare test request
        AmpleFlowEnrichAndSequence.AmpRequest req = new AmpleFlowEnrichAndSequence.AmpRequest();
        req.contactId = testContact.Id;
        req.apiKey = 'invalid-api-key';
        req.sequenceId = 'test-sequence-id';
        
        // Mock HTTP callout to simulate enrichment failure
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true));
        
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
        // Get test contact
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'test@example.com' LIMIT 1];
        
        // Prepare test request with override flags
        AmpleFlowEnrichAndSequence.AmpRequest req = new AmpleFlowEnrichAndSequence.AmpRequest();
        req.contactId = testContact.Id;
        req.apiKey = 'test-api-key';
        req.sequenceId = 'test-sequence-id';
        req.ignore_recently_contacted = true;
        req.ignore_exclusion_list = true;
        req.ignore_duplicate_draft = true;
        req.ignore_duplicate_active = true;
        
        // Mock HTTP callouts
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        List<AmpleFlowEnrichAndSequence.AmpResponse> responses = AmpleFlowEnrichAndSequence.run(new List<AmpleFlowEnrichAndSequence.AmpRequest>{req});
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, responses.size(), 'Should return one response');
        System.assertEquals(true, responses[0].success, 'Should be successful');
    }

    @isTest
    static void testEmptyExperiences() {
        // Get test contact
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'test@example.com' LIMIT 1];
        
        // Prepare test request
        AmpleFlowEnrichAndSequence.AmpRequest req = new AmpleFlowEnrichAndSequence.AmpRequest();
        req.contactId = testContact.Id;
        req.apiKey = 'test-api-key';
        req.sequenceId = 'test-sequence-id';
        
        // Mock HTTP callout with empty experiences
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(false, true));
        
        Test.startTest();
        List<AmpleFlowEnrichAndSequence.AmpResponse> responses = AmpleFlowEnrichAndSequence.run(new List<AmpleFlowEnrichAndSequence.AmpRequest>{req});
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, responses.size(), 'Should return one response');
        System.assertEquals(true, responses[0].success, 'Should be successful');
    }

    // Mock HTTP Response Generator
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private Boolean shouldFail;
        private Boolean emptyExperiences;
        
        public MockHttpResponseGenerator() {
            this.shouldFail = false;
            this.emptyExperiences = false;
        }
        
        public MockHttpResponseGenerator(Boolean shouldFail) {
            this.shouldFail = shouldFail;
            this.emptyExperiences = false;
        }
        
        public MockHttpResponseGenerator(Boolean shouldFail, Boolean emptyExperiences) {
            this.shouldFail = shouldFail;
            this.emptyExperiences = emptyExperiences;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (shouldFail) {
                res.setStatusCode(400);
                res.setBody('{"error": "Bad Request"}');
            } else if (req.getEndpoint().contains('/people/find')) {
                // Mock enrichment response
                res.setStatusCode(200);
                String experiences = emptyExperiences ? '[]' : 
                    '[{"company_name": "Test Company", "title": "Developer", "start_date": "2020-01", "end_date": "2021-01"}]';
                res.setBody('{"first_name": "Test", "last_name": "User", "linkedin_url": "https://linkedin.com/in/test", "title": "Developer", "experiences": ' + experiences + '}');
            } else if (req.getEndpoint().contains('/sequences/')) {
                // Mock sequence response
                res.setStatusCode(200);
                res.setBody('{"success": true}');
            }
            
            return res;
        }
    }
} 