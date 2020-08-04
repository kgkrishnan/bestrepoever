global class JunkContactJunkCharsNoTHDateNoChild implements Database.Batchable<SObject>
{
    List<CampaignMember> campaignMemberResultList;
    Set<Id> campaignMemberResultSet = new Set<Id>();

    List<DRM_Dev_Org__c> drmDevOrgResultList;
    Set<Id> drmDevOrgResultSet = new Set<Id>();

    List<Test_Taker__c> testTakerResultList;
    Set<Id> testTakerResultSet = new Set<Id>();

    List<LiveChatTranscript> chatTranscriptResultList;
    Set<Id> chatTranscriptResultSet = new Set<Id>();

    public String NamejunkMatchPatterns = '\\[\\]\\{\\}!@#$%^*';
    public String EmailjunkMatchPatterns = '!$%^*?\'{}|+=';
         
     global Database.QueryLocator start(Database.BatchableContext BC){
        
        ///SOQL Query
        //String query  = 'SELECT Id,FirstName,LastName,Email,Trailhead_Signup_Date__c FROM Contact WHERE Is_Employee__c = false AND Trailhead_Signup_Date__c = null AND LastModifiedDate >= 2020-01-01T00:00:00Z AND LastModifiedDate <= 2020-01-31T00:00:00Z';
        String query  = 'SELECT Id,FirstName,LastName,Email,Trailhead_Signup_Date__c FROM Contact WHERE Is_Employee__c = false AND Trailhead_Signup_Date__c = null';

        system.debug( 'startING method');
        return Database.getQueryLocator(query);
    }

    // global void execute(SchedulableContext sc){
    //     MyJunkCharactersLocatorJob myJunkCharJob = new MyJunkCharactersLocatorJob();
    //     database.executeBatch(myJunkCharJob);

    // }

    global void execute(Database.BatchableContext BC, List<Contact> scope){
        
        system.debug('execute start');
        
        List<JunkContactRecords__c> junkContactWithNoChildren;
        
        //store it in a 'JunkContactRecords__c' custom object
        try {

                 
            //Add Junk Contact records that have no children
            junkContactWithNoChildren = prepareListOfContactsWithNoChild(scope);
            if (junkContactWithNoChildren.size() > 0) 
                System.debug('JunkContactJunkCharsNoTHDateNoChild Execute() BEFORE UPSERT junkContactWithNoChildren.size() ' + junkContactWithNoChildren.size()); 
                upsert junkContactWithNoChildren ContactId__c;
                
                List<JunkContactRecords__c> junkContactToCheck = [SELECT Id,ContactId__c,FirstName__c,LastName__c,Email__c,IsWithJunkChars__c,NoTHSignupDate__c,HasCampaignMember__c,HasDRMDevOrg__c,HasTestTaker__c,HasChatTranscript__c FROM JunkContactRecords__c WHERE FirstName__c LIKE 'TestContactFor$$%'];
                System.debug('JunkContactJunkCharsNoTHDateNoChild Execute() AFTER UPSERT junkContactToCheck.size ' + junkContactToCheck.size()); 
         
       } catch (Exception e) {
        System.debug('JunkContactJunkCharsNoTHDateNoChild Execute() ISSUE ' + e.getMessage());   
       }
        
    }

    global void finish(Database.BatchableContext BC){
        //N/A
    }
    
    private List<JunkContactRecords__c> prepareListOfContactsWithNoChild(List<Contact> contactsToCheck)
    {
        List<JunkContactRecords__c> junkContactsListWithNoChild;
        Map<Id,Contact> contactsToCheckMap = new Map<Id,Contact>(contactsToCheck);
        //Set<Id> originalContactIdsToCheckSet = contactsToCheckMap.keySet().clone();
        Set<Id> junkCharContactIdsSet = new Set<Id>();

        try {
        
            //Below set, post processing ,will be left with only those Contacts 
            //that have no Children across(TH Module, Unit, Badge etc..)
            //Set<Id> contactIdsForJunkProcessingSet = originalContactIdsToCheckSet;

            //From the function parameter [Contacts set] get only those items that have Junk 
            //in FirstName OR LastName OR Email or in more than one of these fields [FirstName, LastName, Email]
            for (Contact contactTocheck : contactsToCheck) {
                if( ((contactTocheck.FirstName != null) && (string.valueof(contactTocheck.FirstName).containsAny(NamejunkMatchPatterns))) || (string.valueof(contactTocheck.lastname).containsAny(NamejunkMatchPatterns)) || ((contactTocheck.Email != null) && (string.valueof(contactTocheck.Email).containsAny(EmailjunkMatchPatterns))) ){
                    
                    junkCharContactIdsSet.add(contactTocheck.Id);
                }

               /*  if( ((contactTocheck.FirstName != null) && (!string.valueof(contactTocheck.FirstName).containsAny(NamejunkMatchPatterns))) || (!string.valueof(contactTocheck.lastname).containsAny(NamejunkMatchPatterns)) || ((contactTocheck.Email != null) && (!string.valueof(contactTocheck.Email).containsAny(EmailjunkMatchPatterns))) ){
                    
                    junkCharContactIdsSet.add(contactTocheck.Id);
                } */
            }

            System.debug('junkCharContactIdsSet Size PRE REMOVE ' + junkCharContactIdsSet.size());
            
            //To each of SOQLs below provide IDs of only those Contacts that have junk in FirstName OR LastName OR Email
            
            Id contactId;

            //SOQL for count of Child1
            //SELECT ContactId ,count(Id) childCount FROM Case GROUP BY ContactId HAVING ContactId IN ('0036F000025xcpIQAQ','0036F00002bo3XVQAY')
            //TrailheadUnitJoinResultList = [SELECT Id,Contact__c FROM Trailhead_Unit__c WHERE Contact__c IN :originalContactIdsToCheckSet];
            //campaignMemberResultList = [SELECT Id,ContactId FROM CampaignMember WHERE ContactId IN :originalContactIdsToCheckSet];
            campaignMemberResultList = [SELECT Id,ContactId FROM CampaignMember WHERE ContactId IN :junkCharContactIdsSet];
           
            //Using child1 AggregateResultList from contactsToCheckMap Weed out those Contacts that have childCount > 0.
            //for (AggregateResult ar : child1AggregateResultList){
            //    child1AggregateResultSet.add((Id)ar.get('Contact__c'));
            //}
            for (CampaignMember childCampaignMemberRecord : campaignMemberResultList){
                contactId = childCampaignMemberRecord.ContactId;
                
                //Multiple child records (for a Contact) will have same ContactId. So, add the
                //Contact od to the set only if its not already in the set.
                if ((contactId != null) && (!campaignMemberResultSet.contains(contactId))) {
                    campaignMemberResultSet.add(contactId);
                }
                contactId = null;

            }

            //DRM_Dev_Org__c-START
            //drmDevOrgResultList = [SELECT Id,Contact__c FROM DRM_Dev_Org__c WHERE Contact__c IN :originalContactIdsToCheckSet];
            drmDevOrgResultList = [SELECT Id,Contact__c FROM DRM_Dev_Org__c WHERE Contact__c IN :junkCharContactIdsSet];
            
            //Using child1 AggregateResultList from contactsToCheckMap Weed out those Contacts that have childCount > 0.
            for (DRM_Dev_Org__c childDRMDevOrgRecord : drmDevOrgResultList){
                contactId = childDRMDevOrgRecord.Contact__c;
                
                //Multiple child records (for a Contact) will have same ContactId. So, add the
                //Contact od to the set only if its not already in the set.
                if ((contactId != null) && (!drmDevOrgResultSet.contains(contactId))) {
                    drmDevOrgResultSet.add(contactId);
                }
                contactId = null;

            }
            //DRM_Dev_Org__c-END

            
            //Test Taker-START
            //testTakerResultList = [SELECT Id,Contact__c FROM Test_Taker__c WHERE Contact__c IN :originalContactIdsToCheckSet];
            testTakerResultList = [SELECT Id,Contact__c FROM Test_Taker__c WHERE Contact__c IN :junkCharContactIdsSet];
            
            //INSERT FROM UNIT TESTS MIGHT FAIL-Test_Taker__c has before insert, update Trigger that fires below line
            //fflib_SObjectDomain.triggerHandler(TestTakers.class);
            //This has few biz conditions due to which above simple INSERT FROM UNIT TESTS MIGHT FAIL.
            //If So, uncomment below 2 lines to check root cause.
            //System.debug( ' junkCharContactIdsSet Test Taker ' + junkCharContactIdsSet);
            //System.debug('testTakerResultList SIZE ' + testTakerResultList.size());

            //Using child1 AggregateResultList from contactsToCheckMap Weed out those Contacts that have childCount > 0.
            for (Test_Taker__c childTestTakerRecord : testTakerResultList){
                contactId = childTestTakerRecord.Contact__c;
                
                //Multiple child records (for a Contact) will have same ContactId. So, add the
                //Contact od to the set only if its not already in the set.
                if ((contactId != null) && (!testTakerResultSet.contains(contactId))) {
                    testTakerResultSet.add(contactId);
                }
                contactId = null;

            }
            //Test Taker-END

            
            //chatTranscript-START
            //chatTranscriptResultList = [SELECT Id,ContactId FROM LiveChatTranscript WHERE ContactId IN :originalContactIdsToCheckSet];
            chatTranscriptResultList = [SELECT Id,ContactId FROM LiveChatTranscript WHERE ContactId IN :junkCharContactIdsSet];
            
            //Using child1 AggregateResultList from contactsToCheckMap Weed out those Contacts that have childCount > 0.
            for (LiveChatTranscript childChatTranscriptRecord : chatTranscriptResultList){
                contactId = childChatTranscriptRecord.ContactId;
                
                //Multiple child records (for a Contact) will have same ContactId. So, add the
                //Contact od to the set only if its not already in the set.
                if ((contactId != null) && (!chatTranscriptResultSet.contains(contactId))) {
                    chatTranscriptResultSet.add(contactId);
                }
                contactId = null;

            }
            //ChatTranscript-END
        
            //Club Child1Set and Child2Set into a single Master Set to use for filtering from
            Set<Id> childrenMASTERAggregateResultSet = new Set<Id>();

            //addAll() Adds all of the elements in the specified set to the set that calls the method 
            //if they are not already present.
            childrenMASTERAggregateResultSet.addAll(campaignMemberResultSet);

            System.debug('drmDevOrgResultSet Size  ' + drmDevOrgResultSet.size());

            childrenMASTERAggregateResultSet.addAll(drmDevOrgResultSet);

            System.debug('childrenMASTERAggregateResultSet Size Step 1 ' + childrenMASTERAggregateResultSet.size());

            childrenMASTERAggregateResultSet.addAll(testTakerResultSet);

            System.debug('chatTranscriptResultSet Size  ' + chatTranscriptResultSet.size());

            childrenMASTERAggregateResultSet.addAll(chatTranscriptResultSet);

            System.debug('childrenMASTERAggregateResultSet Size Step 2 ' + childrenMASTERAggregateResultSet.size());
            
                
            //Use this Master Set to filter out [using Set.RemoveAll()] items 
            //that are present in Original Set [contactIdsForJunkProcessingSet] and also in this Master set. 
            //That will leave only those contacts in [contactIdsForJunkProcessingSet] 
            //that do not have any children across(TH Module, Unit, Badge etc..)
            //contactIdsForJunkProcessingSet.removeAll(campaignMemberResultSet);
            //contactIdsForJunkProcessingSet.removeAll(childrenMASTERAggregateResultSet);
            junkCharContactIdsSet.removeAll(childrenMASTERAggregateResultSet);
            
            System.debug('junkCharContactIdsSet Size POST REMOVE ' + junkCharContactIdsSet.size());

            //junkContactsListWithNoChild = buildJunkContactsListForChildAggregateSet(contactsToCheckMap,contactIdsForJunkProcessingSet);
            junkContactsListWithNoChild = buildJunkContactsListForChildAggregateSet(contactsToCheckMap,junkCharContactIdsSet);

            System.debug('junkContactsListWithNoChild Size ' + junkContactsListWithNoChild.size());

        } catch (Exception e) {
            System.debug('JunkContactJunkCharsNoTHDateNoChild prepareListOfContactsWithNoChild() ISSUE ' + e.getMessage());             
        }
      return junkContactsListWithNoChild;
    }

    private List<JunkContactRecords__c> buildJunkContactsListForChildAggregateSet(Map<Id,Contact> contactsToCheckMap,
    Set<Id> contactIdsForJunkProcessingSet)
    {
        Contact contactToProcess;
        JunkContactRecords__c junkContact;
        List<JunkContactRecords__c> junkContactsListToAddTo = new List<JunkContactRecords__c>();

        try {
        
            for(Id contactIdValue : contactIdsForJunkProcessingSet){
                system.debug('JunkContactNOTHUnitChildLocatorJob  - buildJunkContactsListForChildAggregateSet method\'s for loop');
                //Get the respective Contact record from contactsToCheck Map
                contactToProcess = contactsToCheckMap.get(contactIdValue);
                    if (contactToProcess != null) {
                        junkContact    = new JunkContactRecords__c(); 
                        junkContact.ContactId__c = contactToProcess.Id; //this will be used in Upsert
                        junkContact.FirstName__c = contactToProcess.FirstName;
                        junkContact.LastName__c = contactToProcess.LastName;
                        junkContact.Email__c = contactToProcess.Email;

                        if( ((contactToProcess.FirstName != null) 
                        && (string.valueof(contactToProcess.FirstName).containsAny(NamejunkMatchPatterns))) 
                        || (string.valueof(contactToProcess.lastname).containsAny(NamejunkMatchPatterns)) 
                        || ((contactToProcess.Email != null) 
                        && (string.valueof(contactToProcess.Email).containsAny(EmailjunkMatchPatterns))) ){
                    
                            junkContact.IsWithJunkChars__c = true;
                        }

                        if (contactToProcess.Trailhead_Signup_Date__c == null) {
                            junkContact.NoTHSignupDate__c = true;
                        }
                        /* if (contactToProcess.DRM_Signup_Date__c == null) {
                            junkContact.NoDRMSignupDate__c = true;
                        } */

                        if (campaignMemberResultSet.contains(contactIdValue)) {
                            junkContact.HasCampaignMember__c = true;
                        }

                        if (DRMDevOrgResultSet.contains(contactIdValue)) {
                            junkContact.HasDRMDevOrg__c = true;
                        }
                        
                        if (TestTakerResultSet.contains(contactIdValue)) {
                              junkContact.HasTestTaker__c = true;
                         }

                        if (chatTranscriptResultSet.contains(contactIdValue)) {
                            junkContact.HasChatTranscript__c = true;
                         }

                        // //junkContact.IsWithNOTHUnitJoin__c = true;;
                        junkContactsListToAddTo.add(junkContact);  
                    }
                    contactToProcess = null;
                    junkContact = null;
            }

        } catch (Exception e) {
            System.debug('JunkContactJunkCharsNoTHDateNoChild buildJunkContactsListForChildAggregateSet() ISSUE ' + e.getMessage());             
        }

        return junkContactsListToAddTo;
    }

}
