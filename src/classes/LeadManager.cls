@RestResource(UrlMapping='/Lead ')
global with sharing class LeadManager {

    @HttpPost
    global static String getLead() {

        String leadID = LeadManager.validateId(LeadManager.getRest());


        if (leadID != null) {
            return leadID;
        } else {
            return 'Lead NOT Found';
        }
    }

    @HttpPut
    global static Id taskForLead() {

        Task taskForId;

        String [] subjectPicklist = new List<String>();
        subjectPicklist.add('Call');
        subjectPicklist.add('Email');
        subjectPicklist.add('Send Letter');
        subjectPicklist.add('Send Quote');
        subjectPicklist.add('Other');

        String leadID = LeadManager.validateId(LeadManager.getRest());
        Map<String, Object> taskforlead = LeadManager.getRest();

        Map<String, Object> subject = (Map< String, Object >) taskforlead.get('subject');

        for (String key : subject.keySet()) {
            Object value = subject.get(key);
            if (leadID != null) {
                taskForId = new Task(
                        Subject = (String) value,
                        WhoId = 'leadId',
                        WhatId = 'SFDC Computing',
                        OwnerId = '0055j000006LEeMAAW',
                        Status = 'No Sorted'
                );
            } else {
                System.debug(LoggingLevel.ERROR, 'Could not create task');
                return 'Could not create task without Name (Lead/Case)';
            }
        }
        insert taskForId;

        return taskForId.Id;

    }

    public static String validateId(Map<String, Object> result) {

        Integer idLength = 18;
        Lead leadPassedResult;

        try {
            String idResult = '%' + result.get('id').toString() + '%';
            String emailResult = '%' + result.get('email').toString() + '%';
            Boolean idValue = idResult.contains('a-zA-Z0-9') && idResult.length() == idLength;
            Boolean emailValue = emailResult.contains('a-zA-Z0-9' + '@');

            if (idResult != null && idValue) {
                leadPassedResult = [
                        SELECT Name,
                                Email,
                                Status
                        FROM Lead
                        WHERE Id = :idResult
                        ORDER BY Name
                        LIMIT 1
                ];
            } else if (idResult != null && emailValue) {
                leadPassedResult = [
                        SELECT
                                Name,
                                Email,
                                Status
                        FROM Lead
                        WHERE Id = :emailResult
                        ORDER BY Name
                        LIMIT 1
                ];
            } else {
                System.debug(LoggingLevel.ERROR, 'Lead NOT Found');
                return 'Lead NOT Found';
            }
            return leadPassedResult.Id;

        } catch (NullPointerException ex) {
            System.debug(LoggingLevel.INFO, 'EXCEPTION' + ex);
            return ex.getMessage();
        }

    }

    public static Map< String, Object > getRest() {

        RestRequest restRequest = RestContext.request;

        String reqToString = restRequest.requestBody.toString();

        Map<String, Object> result = (Map<String, Object>)
                JSON.deserializeUntyped(reqToString);
        return result;
    }


}