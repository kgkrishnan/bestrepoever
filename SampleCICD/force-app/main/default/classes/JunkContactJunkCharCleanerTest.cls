@IsTest
private class JunkContactJunkCharCleanerTest {
    
    static void setupData(String contactFirstName) {

        List<Contact> testContacts = new List<Contact>();
        // Create  Contacts to Cleanse
        for(Integer i=0;i<1;i++) 
        {
            //Is_Employee__c is a Formula(Chckbox). 
            //It will be  false if CONTAINS(Email, "@salesforce.com") = false
            testContacts.add(new Contact(FirstName = contactFirstName+i, LastName='Junk Clean'));
        }
    
        insert testContacts;

        List<Contact> contacts = new List<Contact>();
        contacts = [SELECT Id FROM Contact WHERE FirstName LIKE :contactFirstName+'%'];
        System.debug('contacts IN setupData() METHOD ' + contacts);

        //JunkContactRecords__c test records
        List<JunkContactRecords__c> testJunkContactRecordsList = new List<JunkContactRecords__c>();
        for(Integer i=0;i<1;i++) {
            
            testJunkContactRecordsList.add(new JunkContactRecords__c(FirstName__c = contactFirstName, 
            ContactId__c=contacts[0].Id, ContactJunkCharsCleaned__c = false, ContactMarkedHasJunkChars__c = true, 
            IsWithJunkChars__c = true));
        }

        insert testJunkContactRecordsList;

        List<JunkContactRecords__c> junkcontacts = new List<JunkContactRecords__c>();
        junkcontacts = [SELECT Id FROM JunkContactRecords__c WHERE FirstName__c LIKE :contactFirstName+'%'];
        System.debug('junkcontacts IN setupData() METHOD ' + junkcontacts);
    }

    @IsTest
    static void markJunkContacts(){
        
        String toCreateContactFirstName = 'TestContactFor#*';
        setupData(toCreateContactFirstName);

        Test.startTest();
        JunkContactJunkCharCleaner batchJobToTest = new JunkContactJunkCharCleaner();
        ID jobId = Database.executeBatch(batchJobToTest);
        Test.stopTest();

        //SOQL to get Contacts Marked
        List<Contact> junkContactsMarked = new List<Contact>();

        String NamejunkMatchPatterns = '[\\[\\]\\{\\}!@#$%^*]';
        
        //To WHERE clause send First Name without special characters, 
        //as batch job would have removed it from the Contact's First Name.
        junkContactsMarked = [SELECT Id,FirstName,HasJunkChars__c FROM Contact WHERE FirstName LIKE :toCreateContactFirstName.replaceAll(NamejunkMatchPatterns, '')+'%'];
        System.debug('junkContactsMarked IN TEST METHOD 1 ' + junkContactsMarked);
        
        //SOQL to get Junk Contact Recordss marked/created
        List<JunkContactRecords__c> junkRecordsListUpdated = 
        [SELECT Id,ContactId__c,IsWithJunkChars__c,ContactJunkCharsCleaned__c FROM JunkContactRecords__c 
        WHERE ContactId__c = :junkContactsMarked[0].Id];
        
        System.debug('junkRecordsListUpdated TEST METHOD 1  ' + junkRecordsListUpdated);

        System.assertEquals(1,junkContactsMarked.size());
        //First Name value with special characters removed
        System.assertEquals('TestContactFor0',junkContactsMarked[0].FirstName);
        System.assertEquals(false,junkContactsMarked[0].HasJunkChars__c);

        
        System.assertEquals(1,junkRecordsListUpdated.size());
        System.assertEquals(junkContactsMarked[0].Id,junkRecordsListUpdated[0].ContactId__c);
        System.assertEquals(false,junkRecordsListUpdated[0].IsWithJunkChars__c);
        System.assertEquals(true,junkRecordsListUpdated[0].ContactJunkCharsCleaned__c);
        
    }

    @IsTest
    static void simulateExceptionForFinishMethod(){
        
        //Create a Contact that trigger custom Exception in Batch job
        //Do not change First Name value specfied. That FirstName value used to raise custom exception in batch job.
        String toCreateContactFirstName = 'TestContactFor!@#$^*';
        setupData(toCreateContactFirstName);

        try {

            Test.startTest();
            JunkContactJunkCharCleaner batchJobToTest = new JunkContactJunkCharCleaner();
            ID jobId = Database.executeBatch(batchJobToTest);
            Test.stopTest();
            
        } catch (Exception e) {
            System.assertEquals('Sample text', e.getMessage());
        }
        
    }
}
