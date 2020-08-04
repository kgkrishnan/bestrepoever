global class JunkContactDRMSignDateNoTBIDNoChild implements Database.Batchable<SObject>
{
    // public Datetime recordsFromDate;
    // public Datetime recordsToDate;

    public String recordsFromDate;
    public String recordsToDate;

    public class NullDateValueException extends Exception {}

    List<CampaignMember> campaignMemberResultList;
    Set<Id> campaignMemberResultSet = new Set<Id>();

    List<DRM_Dev_Org__c> drmDevOrgResultList;
    Set<Id> drmDevOrgResultSet = new Set<Id>();

    List<Test_Taker__c> testTakerResultList;
    Set<Id> testTakerResultSet = new Set<Id>();

    List<LiveChatTranscript> chatTranscriptResultList;
    Set<Id> chatTranscriptResultSet = new Set<Id>();
         
     global Database.QueryLocator start(Database.BatchableContext BC){
        
        /* if ((recordsFromDate == null) || (recordsToDate == null))
        {
            throw new NullDateValueException('FromDate or ToDate or both values not specified for SOQL to pick records');
        } */
               
        if (String.isEmpty(recordsFromDate) || String.isEmpty(recordsToDate))
        {
            throw new NullDateValueException('FromDate or ToDate or both values not specified for SOQL to pick records');
        }

        //SOQL Query
        //String query  = 'SELECT Id,FirstName,LastName,Email,DRM_Signup_Date__c,TBID__c FROM Contact WHERE Is_Employee__c = false AND DRM_Signup_Date__c != null AND TBID__c = null AND LastModifiedDate >= 2018-01-01T00:00:00Z AND LastModifiedDate <= 2018-12-31T00:00:00Z';
        //String query  = 'SELECT Id,FirstName,LastName,Email,DRM_Signup_Date__c,TBID__c FROM Contact WHERE Is_Employee__c = false AND DRM_Signup_Date__c != null AND TBID__c = null';
        //String query  = 'SELECT Id,FirstName,LastName,Email,DRM_Signup_Date__c,TBID__c FROM Contact WHERE Is_Employee__c = false AND DRM_Signup_Date__c != null AND TBID__c = null AND LastModifiedDate >= ' + recordsFromDate.formatGMT('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'') + ' AND  LastModifiedDate <= ' + recordsToDate.formatGMT('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
        String query  = 'SELECT Id,FirstName,LastName,Email,DRM_Signup_Date__c,TBID__c FROM Contact WHERE Is_Employee__c = false AND DRM_Signup_Date__c != null AND TBID__c = null AND LastModifiedDate >= ' + recordsFromDate + ' AND  LastModifiedDate <= ' + recordsToDate;
        system.debug( 'query ' + query);
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
                upsert junkContactWithNoChildren ContactId__c;
         
       } catch (Exception e) {
        System.debug('JunkContactDRMSignDateNoTBIDNoChild Execute() ISSUE ' + e.getMessage());   
       }
        
    }

    global void finish(Database.BatchableContext BC){
        //N/A
    }
    
    private List<JunkContactRecords__c> prepareListOfContactsWithNoChild(List<Contact> contactsToCheck)
    {
        List<JunkContactRecords__c> junkContactsListWithNoChild;
        Map<Id,Contact> contactsToCheckMap = new Map<Id,Contact>(contactsToCheck);
        Set<Id> originalContactIdsToCheckSet = contactsToCheckMap.keySet().clone();
      
        try {
        
            //Below set, post processing ,will be left with only those Contacts 
            //that have no Children across(TH Module, Unit, Badge etc..)
            Set<Id> contactIdsForJunkProcessingSet = originalContactIdsToCheckSet;

            System.debug('contactIdsForJunkProcessingSet Size PRE REMOVE ' + contactIdsForJunkProcessingSet.size());

            Id contactId;

            //SOQL for count of Child1
            //SELECT ContactId ,count(Id) childCount FROM Case GROUP BY ContactId HAVING ContactId IN ('0036F000025xcpIQAQ','0036F00002bo3XVQAY')
            //TrailheadUnitJoinResultList = [SELECT Id,Contact__c FROM Trailhead_Unit__c WHERE Contact__c IN :originalContactIdsToCheckSet];
            campaignMemberResultList = [SELECT Id,ContactId FROM CampaignMember WHERE ContactId IN :originalContactIdsToCheckSet];
            
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
            drmDevOrgResultList = [SELECT Id,Contact__c FROM DRM_Dev_Org__c WHERE Contact__c IN :originalContactIdsToCheckSet];
           
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
            testTakerResultList = [SELECT Id,Contact__c FROM Test_Taker__c WHERE Contact__c IN :originalContactIdsToCheckSet];
            
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
            chatTranscriptResultList = [SELECT Id,ContactId FROM LiveChatTranscript WHERE ContactId IN :originalContactIdsToCheckSet];
            
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
            
            System.debug('campaignMemberResultSet Size  ' + campaignMemberResultSet.size());

            childrenMASTERAggregateResultSet.addAll(campaignMemberResultSet);

            System.debug('childrenMASTERAggregateResultSet Size Step 1 ' + childrenMASTERAggregateResultSet.size());
            
            System.debug('drmDevOrgResultSet Size  ' + drmDevOrgResultSet.size());

            childrenMASTERAggregateResultSet.addAll(drmDevOrgResultSet);

            System.debug('childrenMASTERAggregateResultSet Size Step 2 ' + childrenMASTERAggregateResultSet.size());

            System.debug('testTakerResultSet Size  ' + testTakerResultSet.size());

            childrenMASTERAggregateResultSet.addAll(testTakerResultSet);
            System.debug('childrenMASTERAggregateResultSet Size Step 3 ' + childrenMASTERAggregateResultSet.size());

            System.debug('chatTranscriptResultSet Size  ' + chatTranscriptResultSet.size());

            childrenMASTERAggregateResultSet.addAll(chatTranscriptResultSet);

            System.debug('childrenMASTERAggregateResultSet Size Step 4 ' + childrenMASTERAggregateResultSet.size());
                
            //Use this Master Set to filter out [using Set.RemoveAll()] items 
            //that are present in Original Set [contactIdsForJunkProcessingSet] and also in this Master set. 
            //That will leave only those contacts in [contactIdsForJunkProcessingSet] 
            //that do not have any children across(TH Module, Unit, Badge etc..)
            //contactIdsForJunkProcessingSet.removeAll(campaignMemberResultSet);
            contactIdsForJunkProcessingSet.removeAll(childrenMASTERAggregateResultSet);
            
            System.debug('contactIdsForJunkProcessingSet Size POST REMOVE ' + contactIdsForJunkProcessingSet.size());
            System.debug('contactIdsForJunkProcessingSet POST REMOVE ' + contactIdsForJunkProcessingSet);

            junkContactsListWithNoChild = buildJunkContactsListForChildAggregateSet(contactsToCheckMap,contactIdsForJunkProcessingSet);
            System.debug('junkContactsListWithNoChild Size ' + junkContactsListWithNoChild.size());

        } catch (Exception e) {
            System.debug('JunkContactDRMSignDateNoTBIDNoChild prepareListOfContactsWithNoChild() ISSUE ' + e.getMessage());             
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
                system.debug('JunkContactDRMSignDateNoTBIDNoChild  - buildJunkContactsListForChildAggregateSet method\'s for loop');
                //Get the respective Contact record from contactsToCheck Map
                contactToProcess = contactsToCheckMap.get(contactIdValue);
                    if (contactToProcess != null) {
                        junkContact    = new JunkContactRecords__c(); 
                        junkContact.ContactId__c = contactToProcess.Id; //this will be used in Upsert
                        junkContact.FirstName__c = contactToProcess.FirstName;
                        junkContact.LastName__c = contactToProcess.LastName;
                        junkContact.Email__c = contactToProcess.Email;

                        if (contactToProcess.DRM_Signup_Date__c != null) {
                            junkContact.NoDRMSignupDate__c = false;
                        }

                        if (contactToProcess.TBID__c == null) {
                            junkContact.IsWithNoTBID__c = true;
                        }
                        
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

                        junkContactsListToAddTo.add(junkContact);  
                    }
                    contactToProcess = null;
                    junkContact = null;
            }

        } catch (Exception e) {
            System.debug('JunkContactDRMSignDateNoTBIDNoChild buildJunkContactsListForChildAggregateSet() ISSUE ' + e.getMessage());             
        }

        return junkContactsListToAddTo;
    }

}
