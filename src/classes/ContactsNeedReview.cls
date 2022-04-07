public class ContactsNeedReview implements Database.Batchable<sObject>, Database.Stateful { // В название батча всегда добавляем Batch 


    static final String OUTDATED = 'Possible_Outdated__c = TRUE';
    static final String TEMPNAME = 'ContactOutdate';
    Map<Id, List<Contact>> contactwithSameOwner = new Map<Id, List<Contact>>(); // Что-то с форматом названия. Когда называем мапу -пишем что по чему - contactsByOwner
    Set<Id> idOwnersForEmail = new Set<Id>();// ownersIdForEmail ) 

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String contactQuery = 'SELECT Name, AccountId, OwnerId, Phone ' +
                'FROM Contact Where  OUTDATED';
        return Database.getQueryLocator(contactQuery);
    }

    public void execute(Database.BatchableContext bc, List<Contact> records) {

        for (Integer i = 0; i < records.size(); i++) {
            idOwnersForEmail.add(records.get(i).OwnerId);//records[i]
        }

        for (Id owner : idOwnersForEmail) {// Неоптимальная реализация, но ок
            List<Contact> contacts = new List<Contact>();
            for (Contact contact : records) {
                contacts.add(contact);
                if (Contact.OwnerId == owner) {
                    contactwithSameOwner.put(Contact.OwnerId, contacts);
                } else {
                    idOwnersForEmail.add(Contact.OwnerId);//А зачем если у нас есть айдишки уже в мапе?
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
            mail.setSenderDisplayName('Batch Processing');//Это же результаты)
            mail.setTemplateID(emailTemplate.Id);
            messages = new List<Messaging.SingleEmailMessage>{
                    mail
            } ;//Забыла сетать кому отправлять)
        }

        Messaging.SendEmailResult[] results =
                Messaging.sendEmail(messages);

        System.debug(LoggingLevel.ERROR, 'The email failed to send: ');//Хммммммм

    }
}
