global class JunkContactJunkCharCleaner implements Database.Batchable<SObject>, Database.Stateful
{
    String NamejunkMatchPatterns = '[\\[\\]\\{\\}!@#$%^*]';
    String EmailjunkMatchPatterns = '[#!$%^*?\'\\{\\}|\\+=]';

    Exception[] errors = new Exception[0];

    //To simulate an exception to aid Code Coverage of finish() method during Unit Testing
    public class ForUnitTestingException extends Exception {}

    global Database.QueryLocator start(Database.BatchableContext bc) {

        //SOQL Query
        //LIMIT 2';
        string query = 'SELECT Id,ContactId__c,FirstName__c,ContactJunkCharsCleaned__c,IsWithJunkChars__c '+
        ' FROM JunkContactRecords__c WHERE ContactJunkCharsCleaned__c= false AND ContactMarkedHasJunkChars__c = true '+
        ' AND IsWithJunkChars__c = true';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<JunkContactRecords__c> scope){
        
       try {

            //Set<Id> contactIds = (new Map<Id,JunkContactRecords__c>(junkContacts)).keySet().clone();

            Set<String> identifiedJunkContactsIds = new Set<String>();
            for(JunkContactRecords__c junkRecord : scope){

                //Simulate an exception for Unit Test Code Coverage
                //Do not change First Name value specfied. That FirstName value used to raise custom exception in batch job.
                if (junkRecord.FirstName__c == 'TestContactFor!@#$^*') 
                    throw new ForUnitTestingException('For Code Coverage of finish() method through Unit Testing');

                identifiedJunkContactsIds.add(junkRecord.ContactId__c);
            }

            //Code to Update Contact with junk characters removed
            List<Contact> junkContactsToFix = [SELECT Id,FirstName,LastName,Email,HasJunkChars__c FROM Contact Where Id IN: identifiedJunkContactsIds ];
            List<Contact> junkContactsFixed = new List<Contact>();
            JunkContactRecords__c junkRecordToUpdate;
            List<JunkContactRecords__c> junkRecordsListToUpdate = new List<JunkContactRecords__c>();

            for (Contact contactToFix : junkContactsToFix) {
                
                if (contactToFix.FirstName != null) {
                    contactToFix.FirstName = contactToFix.FirstName.replaceAll(NamejunkMatchPatterns, ''); 
                } 

                contactToFix.LastName = contactToFix.LastName.replaceAll(NamejunkMatchPatterns, '');

                if (contactToFix.Email != null) {
                    contactToFix.Email = contactToFix.Email.replaceAll(EmailjunkMatchPatterns, '');    
                } 

                contactToFix.HasJunkChars__c = false;

                junkContactsFixed.add(contactToFix);

                //Mark the JunkContact (Custom Entity) Record's field ContactJunkCharsCleaned__c = true.
                junkRecordToUpdate = new JunkContactRecords__c();
                junkRecordToUpdate.ContactId__c = contactToFix.Id;
                junkRecordToUpdate.IsWithJunkChars__c = false; //Since this contact is now marked as cleaned
                junkRecordToUpdate.ContactJunkCharsCleaned__c = true; //Since this contact is now marked as cleaned
                junkRecordsListToUpdate.add(junkRecordToUpdate);
                        
            }

            if (junkContactsFixed.size() > 0) {

                update junkContactsFixed;
            }
        
            if (junkRecordsListToUpdate.size() > 0) {

                upsert junkRecordsListToUpdate ContactId__c;
            }
        
            
        } catch (Exception ex) {
            System.debug('JunkContactJunkCharCleaner execute() ISSUE ' + ex.getMessage());
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
            System.debug('JunkContactJunkCharCleaner finish() ISSUE ' + ex.getMessage());
        }
        
    }

}
