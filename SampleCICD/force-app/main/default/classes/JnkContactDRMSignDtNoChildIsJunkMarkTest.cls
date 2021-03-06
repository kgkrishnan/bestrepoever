@isTest
private class JnkContactDRMSignDtNoChildIsJunkMarkTest {
    
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
            
            testJunkContactRecordsList.add(new JunkContactRecords__c(FirstName__c=contactFirstName,ContactId__c=contacts[0].Id));
        }

        insert testJunkContactRecordsList;
    }

    @IsTest
    static void markJunkContacts(){
        
        String toCreateContactFirstName = 'TestContactFor!@';
        setupData(toCreateContactFirstName);

        Test.startTest();
        JunkContactDRMSignDtNoChildIsJunkMark batchJobToTest = new JunkContactDRMSignDtNoChildIsJunkMark();
        ID jobId = Database.executeBatch(batchJobToTest);
        Test.stopTest();

        //SOQL to get Contacts Marked
        List<Contact> junkContactsMarked = new List<Contact>();

        junkContactsMarked = [SELECT Id,IsJunk__c FROM Contact WHERE FirstName LIKE :toCreateContactFirstName+'%'];
        System.debug('junkContactsMarked IN TEST METHOD 1 ' + junkContactsMarked);
        
        //SOQL to get Junk Contact Recordss marked/created
        List<JunkContactRecords__c> junkRecordsListUpdated = [SELECT Id,ContactId__c,ContactMarkedIsJunk__c FROM JunkContactRecords__c WHERE ContactId__c = :junkContactsMarked[0].Id];
        System.debug('junkRecordsListUpdated TEST METHOD 1  ' + junkRecordsListUpdated);

        System.assertEquals(1,junkContactsMarked.size());
        System.assertEquals(true,junkContactsMarked[0].IsJunk__c);
       
        System.assertEquals(1,junkRecordsListUpdated.size());
        System.assertEquals(junkContactsMarked[0].Id,junkRecordsListUpdated[0].ContactId__c);
        System.assertEquals(true,junkRecordsListUpdated[0].ContactMarkedIsJunk__c);

    }


    @IsTest
    static void simulateExceptionForFinishMethod(){
        
        //Create a Contact that trigger custom Exception in Batch job
        String toCreateContactFirstName = 'TestContactFor!@#$^*';
        setupData(toCreateContactFirstName);

        try {

            Test.startTest();
            JunkContactDRMSignDtNoChildIsJunkMark batchJobToTest = new JunkContactDRMSignDtNoChildIsJunkMark();
            ID jobId = Database.executeBatch(batchJobToTest);
            Test.stopTest();
            
        } catch (Exception e) {
            System.assertEquals('Sample text', e.getMessage());
        }
        
    }
}
