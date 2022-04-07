@RestResource(UrlMapping='/Lead ')
global with sharing class LeadManager {//Manager это support класс который отвечает за получение данных из БД. Тогда как REST класс должен быть REST классом)

    @HttpPost
    global static String getLead() {

        String leadID = LeadManager.validateId(LeadManager.getRest());


        if (leadID != null) {
            return leadID;//Нам нужна вся информация по лиду, не только его айдишка)
        } else {
            return 'Lead NOT Found';
        }
    }

    @HttpPut
    global static Id taskForLead() {

        Task taskForId;

        String [] subjectPicklist = new List<String>();//Где-то я это уже видел, код ниже можно заменить на присвоение конструктору 
        subjectPicklist.add('Call');
        subjectPicklist.add('Email');
        subjectPicklist.add('Send Letter');
        subjectPicklist.add('Send Quote');
        subjectPicklist.add('Other');

        String leadID = LeadManager.validateId(LeadManager.getRest());
        Map<String, Object> taskforlead = LeadManager.getRest();

        Map<String, Object> subject = (Map< String, Object >) taskforlead.get('subject');

        for (String key : subject.keySet()) {
            Object value = subject.get(key);//Сразу приводи тип в строку
            if (leadID != null) {
                taskForId = new Task(
                        Subject = (String) value,//Читай задание, плсю проверка на пустоту отсутствует
                        WhoId = 'leadId',//wut
                        WhatId = 'SFDC Computing',
                        OwnerId = '0055j000006LEeMAAW',//Отвратительно
                        Status = 'No Sorted'
                );
            } else {
                System.debug(LoggingLevel.ERROR, 'Could not create task');
                return 'Could not create task without Name (Lead/Case)';//Посмотри на тип возвращаемого значения метода... Что-то не так
            }
        }
        insert taskForId;

        return taskForId.Id;

    }

    public static String validateId(Map<String, Object> result) {

        Integer idLength = 18;
        Lead leadPassedResult;

        try {
            String idResult = '%' + result.get('id').toString() + '%';//Уже видел, упадет
            String emailResult = '%' + result.get('email').toString() + '%';// same
            Boolean idValue = idResult.contains('a-zA-Z0-9') && idResult.length() == idLength;//Айдишки бывают 2х типов по количеству символов...
            Boolean emailValue = emailResult.contains('a-zA-Z0-9' + '@');//А зачем + ?

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
            return leadPassedResult.Id;//Упадет если не найдены совпадения

        } catch (NullPointerException ex) {
            System.debug(LoggingLevel.INFO, 'EXCEPTION' + ex);
            return ex.getMessage();
        }

    }

    public static Map< String, Object > getRest() {//Название

        RestRequest restRequest = RestContext.request;

        String reqToString = restRequest.requestBody.toString();

        Map<String, Object> result = (Map<String, Object>)
                JSON.deserializeUntyped(reqToString);
        return result;
    }


}
