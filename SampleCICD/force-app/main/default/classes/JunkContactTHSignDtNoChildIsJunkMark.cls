global class JunkContactTHSignDtNoChildIsJunkMark implements Database.Batchable<SObject>, Database.Stateful
{
    Exception[] errors = new Exception[0];

    //To simulate an exception to aid Code Coverage of finish() method during Unit Testing
    public class ForUnitTestingException extends Exception {}

    global Database.QueryLocator start(Database.BatchableContext bc) {

        //SOQL Query
        /*'SELECT Id,ContactId__c,ContactMarkedIsJunk__c FROM JunkContactRecords__c '+
            ' WHERE ContactMarkedIsJunk__c= false AND NoTHSignupDate__c= false AND IsWithNoTBID__c = true AND '+
            ' HasCampaignMember__c = false AND HasTHUnitJoin__c = false AND HasTHFavorites__c = false AND '+ 
            ' HasChatTranscript__c = false AND HasDRMDevOrg__c = false AND HasTestTaker__c = false AND '+
        
        ' ContactId__c IN (\'003F000001ZxR5cIAF\',\'0032A00002cyEaLQAU\', \'0032A00002giLMbQAM\','+
         '\'0032A00002giLMcQAM\', \'0032A00002giEicQAE\', \'0032A00002giLM3QAM\')'; */
            
            // string query = 'SELECT Id,ContactId__c,FirstName__c,ContactMarkedIsJunk__c FROM JunkContactRecords__c '+
            // ' WHERE ContactMarkedIsJunk__c= false AND NoTHSignupDate__c= false AND IsWithNoTBID__c = true AND '+
            // ' HasCampaignMember__c = false AND HasTHUnitJoin__c = false AND HasTHFavorites__c = false AND '+ 
            // ' HasChatTranscript__c = false AND HasDRMDevOrg__c = false AND HasTestTaker__c = false ';

            //Removed ContactMarkedIsJunk__c= false Condition. Else its not picking rows even if there.
            string query = 'SELECT Id,ContactId__c,FirstName__c,ContactMarkedIsJunk__c FROM JunkContactRecords__c '+
            ' WHERE NoTHSignupDate__c= false AND IsWithNoTBID__c = true AND '+
            ' HasCampaignMember__c = false AND HasTHUnitJoin__c = false AND HasTHFavorites__c = false AND '+ 
            ' HasChatTranscript__c = false AND HasDRMDevOrg__c = false AND HasTestTaker__c = false ';

            return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<JunkContactRecords__c> scope){

        System.debug('execute start');
       
        try {

            Set<String> identifiedJunkContactsIds = new Set<String>();
            for(JunkContactRecords__c junkRecord : scope){

                //Simulate an exception for Unit Test Code Coverage
                if (junkRecord.FirstName__c == 'TestContactFor!@#$^*') 
                    throw new ForUnitTestingException('For Code Coverage of finish() method through Unit Testing');

                identifiedJunkContactsIds.add(junkRecord.ContactId__c);
            }

            System.debug('identifiedJunkContactsIds size in execute() ' + identifiedJunkContactsIds.size());
            System.debug('identifiedJunkContactsIds in execute() ' + identifiedJunkContactsIds);

            //Code to Update Contact with junk characters removed
            List<Contact> junkContactsToMark = [SELECT Id,IsJunk__c FROM Contact Where Id IN: identifiedJunkContactsIds ];
            
            System.debug('junkContactsToMark List size in execute() ' + junkContactsToMark.size());

            if (junkContactsToMark == null) {
                return;
            }

            List<Contact> junkContactsMarked = new List<Contact>();
            JunkContactRecords__c junkRecordToUpdate;
            List<JunkContactRecords__c> junkRecordsListToUpdate = new List<JunkContactRecords__c>();

            for (Contact contactToMark : junkContactsToMark) {
                contactToMark.IsJunk__c = true;
                junkContactsMarked.add(contactToMark);

                //Mark the JunkContact (Custom Entity) Record's field ContactMarkedIsJunk__c = true.
                junkRecordToUpdate = new JunkContactRecords__c();
                junkRecordToUpdate.ContactId__c = contactToMark.Id;
                junkRecordToUpdate.ContactMarkedIsJunk__c = true; //Since the contact now being marked to junk
                junkRecordsListToUpdate.add(junkRecordToUpdate);
                        
            }

            if (junkContactsMarked.size() > 0) {

                update junkContactsMarked;
            }
        
            if (junkRecordsListToUpdate.size() > 0) {

                upsert junkRecordsListToUpdate ContactId__c;
            }
        
            
        } catch (Exception ex) {
            System.debug('JunkContactTHSignDtNoChildIsJunkMark execute() ISSUE ' + ex.getMessage());
            errors.add(ex);
        }

    }

    global void finish(Database.BatchableContext BC){
        
        /* try/catch around the Messaging.sendEmail in this scenario as often with packages and sandboxes etc... 
        the user running the batch can't send an outbound email. Just something to watch out for is
            the batch might otherwise work and then fall over in the finish method. – Daniel Ballinger Mar 10 '16 at 23:15 */

        try {

            System.debug('IN finish() method outside try block ');

            if (!errors.isEmpty()) {

                System.debug('finish() method errors.toString() ' + errors.toString());
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setSubject('Errors occurred during MyJunkContactCleanerJob batch process');
                mail.setTargetObjectId(UserInfo.getUserId());
                mail.setSaveAsActivity(false);
                //mail.setPlainTextBody(buildBodyFor(errors));
                mail.setPlainTextBody(errors.toString());
    
                Messaging.sendEmail(new Messaging.Email[] { mail });
                
            }
            
        } catch (Exception ex) {
            System.debug('JunkContactTHSignDtNoChildIsJunkMark finish() ISSUE ' + ex.getMessage());
        }
        
    }
   
}
