/*
Author: Eamon Kelly, Enclude
Purpose: Handle request for a list of adverts - only returns adverts for members who are active and the advert is approved
	
Called from: my.salesforce.com/services/apexrest
Tested in: TestRestServices
*/
@RestResource(urlMapping='/adverts')
global with sharing class AdvertsRestService 
{
	@HttpGet
	global static void getAdverts ()
	{
        RestRequest req = RestContext.request;
        RestContext.response.addHeader('Content-Type', 'application/json');
        try
        {
            list <Contact> memberAdverts = [select ID, Name, Text_for_advert__c from Contact where status__c='Active' and Display_advert_on_web_site__c=true];
            RestContext.response.responseBody = Blob.valueOf (JSON.serialize(memberAdverts));
            RestContext.response.statusCode = 200;
        }
        catch (Exception e)
        {
            RestContext.response.statusCode = 404;
        }
	}   
    
}