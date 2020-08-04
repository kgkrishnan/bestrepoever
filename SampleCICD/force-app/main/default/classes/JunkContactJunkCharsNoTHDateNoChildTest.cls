
@isTest
private class JunkContactJunkCharsNoTHDateNoChildTest {
    
     
    static List<Contact> testContacts = new List<Contact>();

    @TestSetup
    public static void setup(){
         // Create  Contacts to shortlist
        //List<Contact> testContacts = new List<Contact>();
        for(Integer i=0;i<3;i++) 
        {
                if (i==0) {
                    //Is_Employee__c is a Formula(Chckbox). It will be  false if CONTAINS(Email, "@salesforce.com") = false
                    testContacts.add(new Contact(FirstName = 'TestContactFor$$'+i, LastName='Junk Clean', Email='TestContact+'+i+'For@sample.com'));
                }
                else if (i == 1) {
                    testContacts.add(new Contact(FirstName = 'TestContactFor'+i, LastName='Junk^ Clean', Email='TestContact'+i+'For@newsample.com'));
                }
                else if (i == 2) {
                    testContacts.add(new Contact(FirstName = 'TestContactFor'+i, LastName='Junk Clean', Email='TestContact{'+i+'For@gosample.com'));
                }
            
        }
    
        insert testContacts;
        System.debug('testContacts[0].Id  '+ testContacts[0].Id);
      

        
   
    }

    static void setupDataWithChildEntities() {

        List<Contact> contactIds = new List<Contact>();
        contactIds = [SELECT Id,FirstName,Email FROM Contact WHERE FirstName LIKE 'TestContactFor$$%'];
        //System.debug('contactIds IN setupDataWithChildEntities() METHOD ' + contactIds);

        //campaignMemberResultList
        List<CampaignMember> testCampaignMemberResultList = new List<CampaignMember>();
        for(Integer i=0;i<1;i++) {
            
            ///Mention Campaign this member belongs to
            testCampaignMemberResultList.add(new CampaignMember(CampaignId='7012A000000oDHyQAM', ContactId=contactIds[0].Id));
        }

        insert testCampaignMemberResultList;

        //DRM Dev Org
        List<DRM_Dev_Org__c> testDrmDevOrgResultList = new List<DRM_Dev_Org__c>();
        for(Integer i=0;i<1;i++) {
            
            testDrmDevOrgResultList.add(new DRM_Dev_Org__c(Contact__c=contactIds[0].Id));
        }

        insert testDrmDevOrgResultList;

        //Test Taker
        List<Test_Taker__c> sampleTestTakerResultList = new List<Test_Taker__c>();
        for(Integer i=0;i<1;i++) {
            
            sampleTestTakerResultList.add(new Test_Taker__c(Contact__c=contactIds[0].Id));
        }

        // Test_Taker__c has before insert, update Trigger that fires below line
        //fflib_SObjectDomain.triggerHandler(TestTakers.class);
        //This has few biz conditions due to which above simple INSERT fails.
        insert sampleTestTakerResultList;
        
        //When above insert fails, uncomment and use below SOQL to check insert error root cause
        //List<Test_Taker__c> TestTakerList = [SELECT Id, Contact__c FROM Test_Taker__c WHERE Contact__c =:contacts[0].Id];
        //System.debug('TestTakerList CHECK ' + TestTakerList);
        

        //Chat Transcript
        List<LiveChatTranscript> testChatTranscriptResultList = new List<LiveChatTranscript>();
        for(Integer i=0;i<1;i++) {
            
            testChatTranscriptResultList.add(new LiveChatTranscript(LiveChatVisitorId='5713k000002ISXcAAO', ContactId=contactIds[0].Id));
        }
        insert testChatTranscriptResultList;

        
    }

    @IsTest
    static void shortListJunkContactWithNoChild(){
        
        Test.startTest();
       
        JunkContactJunkCharsNoTHDateNoChild batchJobToTest = new JunkContactJunkCharsNoTHDateNoChild();
        ID jobId = Database.executeBatch(batchJobToTest);

        Test.stopTest();

        List<Contact> contactIds = new List<Contact>();

        contactIds = [SELECT Id,FirstName,Email FROM Contact WHERE FirstName LIKE 'TestContactFor$$%'];
        //System.debug('contactIds IN TEST METHOD 1 ' + contactIds);
        
        List<JunkContactRecords__c> junkContactToCheck = [SELECT Id,ContactId__c,FirstName__c,LastName__c,Email__c,IsWithJunkChars__c,NoTHSignupDate__c,HasCampaignMember__c,HasDRMDevOrg__c,HasTestTaker__c,HasChatTranscript__c FROM JunkContactRecords__c WHERE ContactId__c = :contactIds[0].Id];
      
        //System.debug('junkContactToCheck  ' + junkContactToCheck);

        System.assertEquals(1,junkContactToCheck.size());
        
        System.assertEquals(contactIds[0].Id,junkContactToCheck[0].ContactId__c);
        System.assertEquals(contactIds[0].FirstName,junkContactToCheck[0].FirstName__c);
        System.assertEquals(contactIds[0].Email,junkContactToCheck[0].Email__c);
        System.assertEquals(true,junkContactToCheck[0].IsWithJunkChars__c);
        System.assertEquals(true,junkContactToCheck[0].NoTHSignupDate__c);

        System.assertEquals(false,junkContactToCheck[0].HasCampaignMember__c);
        System.assertEquals(false,junkContactToCheck[0].HasDRMDevOrg__c);
        System.assertEquals(false,junkContactToCheck[0].HasTestTaker__c);
        System.assertEquals(false,junkContactToCheck[0].HasChatTranscript__c);     
    }

    @IsTest
    static void shortListJunkContactWithChildEntities(){
        
        setupDataWithChildEntities();

        Test.startTest();
        JunkContactJunkCharsNoTHDateNoChild batchJobToTest = new JunkContactJunkCharsNoTHDateNoChild();
        ID jobId = Database.executeBatch(batchJobToTest);
        Test.stopTest();

        List<Contact> contactIds = new List<Contact>();

        contactIds = [SELECT Id,FirstName,Email FROM Contact WHERE FirstName LIKE 'TestContactFor$$%'];
        System.debug('contactIds IN TEST METHOD 2 ' + contactIds);
        
        List<JunkContactRecords__c> junkContactToCheck = [SELECT Id,ContactId__c,FirstName__c,LastName__c,Email__c,IsWithJunkChars__c,NoTHSignupDate__c,HasCampaignMember__c,HasDRMDevOrg__c,HasTestTaker__c,HasChatTranscript__c FROM JunkContactRecords__c WHERE ContactId__c = :contactIds[0].Id];
        System.debug('junkContactToCheck  ' + junkContactToCheck);

        System.assertEquals(0,junkContactToCheck.size());
        
    }
    
    
    @IsTest
    static void ContactJunkLastNameWithTestTakerChildEntitity(){
        
        List<Contact> contacts = new List<Contact>();
        contacts = [SELECT Id FROM Contact WHERE LastName LIKE 'Junk^%'];
        //System.debug('contacts FOR LAST NAME  ' + contacts);
       
        //Test Taker
        List<Test_Taker__c> sampleTestTakerResultList = new List<Test_Taker__c>();
        for(Integer i=0;i<1;i++) {
            
            sampleTestTakerResultList.add(new Test_Taker__c(Contact__c=contacts[0].Id));
        }

        insert sampleTestTakerResultList;

        Test.startTest();
        JunkContactJunkCharsNoTHDateNoChild batchJobToTest = new JunkContactJunkCharsNoTHDateNoChild();
        ID jobId = Database.executeBatch(batchJobToTest);
        Test.stopTest();
        
        List<JunkContactRecords__c> junkContactToCheck = [SELECT Id,ContactId__c,FirstName__c,LastName__c,Email__c,IsWithJunkChars__c,NoTHSignupDate__c,HasCampaignMember__c,HasDRMDevOrg__c,HasTestTaker__c,HasChatTranscript__c FROM JunkContactRecords__c WHERE ContactId__c = :contacts[0].Id];
        //System.debug('junkContactToCheck TEST METHOD 3  ' + junkContactToCheck);

        System.assertEquals(0,junkContactToCheck.size());
        
    }

    @IsTest
    static void ContactJunkEmailWithTestTakerChildEntitity(){
        
        List<Contact> contacts = new List<Contact>();
        contacts = [SELECT Id FROM Contact WHERE Email LIKE 'TestContact{%'];
        //System.debug('contacts FOR JUNK EMAIL ' + contacts);
       
        //Test Taker
        List<Test_Taker__c> sampleTestTakerResultList = new List<Test_Taker__c>();
        for(Integer i=0;i<1;i++) {
            
            sampleTestTakerResultList.add(new Test_Taker__c(Contact__c=contacts[0].Id));
        }

        // Test_Taker__c has before insert, update Trigger that fires below line
        //fflib_SObjectDomain.triggerHandler(TestTakers.class);
        //This has few biz conditions due to which above simple INSERT fails.
        insert sampleTestTakerResultList;
        
        
        //When above insert fails, uncomment and use below SOQL to check insert error root cause
        //List<Test_Taker__c> TestTakerList = [SELECT Id, Contact__c FROM Test_Taker__c WHERE Contact__c =:contacts[0].Id];
        //System.debug('TestTakerList CHECK ' + TestTakerList);

        Test.startTest();
       
        JunkContactJunkCharsNoTHDateNoChild batchJobToTest = new JunkContactJunkCharsNoTHDateNoChild();
        ID jobId = Database.executeBatch(batchJobToTest);

        Test.stopTest();
        
        List<JunkContactRecords__c> junkContactToCheck = [SELECT Id,ContactId__c,FirstName__c,LastName__c,Email__c,IsWithJunkChars__c,NoTHSignupDate__c,HasCampaignMember__c,HasDRMDevOrg__c,HasTestTaker__c,HasChatTranscript__c FROM JunkContactRecords__c WHERE ContactId__c = :contacts[0].Id];
        //System.debug('junkContactToCheck TEST 4 METHOD  ' + junkContactToCheck);

        System.assertEquals(0,junkContactToCheck.size());
        
    }
    
}
