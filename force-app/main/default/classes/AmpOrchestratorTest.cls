@isTest
private class AmpOrchestratorTest {
    @isTest
    static void testHappyPath() {
        // Create test contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'ada@test.com'
        );
        insert testContact;
        
        // Prepare request
        AmpRequest req = new AmpRequest();
        req.contactId = testContact.Id;
        req.apiKey = 'test-api-key';
        req.sequenceId = 'test-sequence';
        req.ignore_recently_contacted = true;
        req.ignore_exclusion_list = true;
        req.ignore_duplicate_draft = true;
        req.ignore_duplicate_active = true;
        
        // Set mock
        Test.setMock(HttpCalloutMock.class, new AmpMock());
        
        Test.startTest();
        List<AmpResponse> responses = AmpOrchestrator.run(new List<AmpRequest>{req});
        Test.stopTest();
        
        // Assertions
        System.assertEquals(1, responses.size(), 'Should return one response');
        System.assertEquals(true, responses[0].success, 'Should be successful');
        
        // Verify task was created
        List<Task> tasks = [SELECT Id, Subject, Description FROM Task WHERE WhatId = :testContact.Id];
        System.assertEquals(1, tasks.size(), 'Should create one task');
        System.assert(tasks[0].Subject.contains('test-sequence'), 'Task subject should contain sequence ID');
    }
    
    @isTest
    static void testEnrich404() {
        // Create test contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'ada@test.com'
        );
        insert testContact;
        
        // Prepare request
        AmpRequest req = new AmpRequest();
        req.contactId = testContact.Id;
        req.apiKey = 'test-api-key';
        req.sequenceId = 'test-sequence';
        
        // Set mock that returns 404
        Test.setMock(HttpCalloutMock.class, new AmpMock());
        
        Test.startTest();
        List<AmpResponse> responses = AmpOrchestrator.run(new List<AmpRequest>{req});
        Test.stopTest();
        
        // Assertions
        System.assertEquals(1, responses.size(), 'Should return one response');
        System.assertEquals(false, responses[0].success, 'Should not be successful');
        System.assert(responses[0].message.contains('404'), 'Error message should mention 404');
    }
} 