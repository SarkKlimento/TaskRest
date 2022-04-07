public class ContactsNeedReview implements Database.Batchable<sObject>, Database.Stateful {


    static final String OUTDATED = 'Possible_Outdated__c = TRUE';
    static final String TEMPNAME = 'ContactOutdate';
    Map<Id, List<Contact>> contactwithSameOwner = new Map<Id, List<Contact>>();
    Set<Id> idOwnersForEmail = new Set<Id>();

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String contactQuery = 'SELECT Name, AccountId, OwnerId, Phone ' +
                'FROM Contact Where  OUTDATED';
        return Database.getQueryLocator(contactQuery);
    }

    public void execute(Database.BatchableContext bc, List<Contact> records) {

        for (Integer i = 0; i < records.size(); i++) {
            idOwnersForEmail.add(records.get(i).OwnerId);
        }

        for (Id owner : idOwnersForEmail) {
            List<Contact> contacts = new List<Contact>();
            for (Contact contact : records) {
                contacts.add(contact);
                if (Contact.OwnerId == owner) {
                    contactwithSameOwner.put(Contact.OwnerId, contacts);
                } else {
                    idOwnersForEmail.add(Contact.OwnerId);
                    contactwithSameOwner.put(Contact.OwnerId, contacts);
                }
            }
        }
    }

    public void finish(Database.BatchableContext bc) {

        Messaging.SingleEmailMessage[] messages;
        //noinspection ApexUnresolvableReference
        EmailTemplate emailTemplate = [
                SELECT Id, Subject, Description,
                        HtmlValue, DeveloperName, Body
                FROM EmailTemplate
                WHERE Name = 'ContactOutdate'
        ];

        for (Id owner : idOwnersForEmail) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setSenderDisplayName('Batch Processing');
            mail.setTemplateID(emailTemplate.Id);
            messages = new List<Messaging.SingleEmailMessage>{
                    mail
            } ;
        }

        Messaging.SendEmailResult[] results =
                Messaging.sendEmail(messages);

        System.debug(LoggingLevel.ERROR, 'The email failed to send: ');

    }
}