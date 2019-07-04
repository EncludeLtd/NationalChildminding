/*
Author: Eamon Kelly, Enclude
Purpose: Handle request for member profiles and changes to it
	
Called from: my.salesforce.com/services/apexrest
Tested in: TestRestServices
*/
@RestResource(urlMapping='/member/*')
global with sharing class MemberRestService 
{
	@HttpPost
	global static void updateMemberDetails (String memberID, String mobile)
	{
		try
		{
			Contact member = new Contact (ID=memberID, MobilePhone=mobile);
			update member;
            RestContext.response.statusCode = 200;
		}
		catch (Exception e)
		{
            RestContext.response.responseBody = Blob.valueOf (JSON.serialize(new JSONError('MEMBER_NOT_FOUND', 'Member not found')));
			RestContext.response.statusCode = 304;
		}
	}   

	class JSONError
	{
		public String errorCode;
		public String message;
		public JSONError (String code, String msg)
		{
			errorCode = code;
			message = msg;
		}
	}
	
	@HttpGet
	global static void getMember ()
	{
        RestRequest req = RestContext.request;
        RestContext.response.addHeader('Content-Type', 'application/json');
        String result='[';
        try
        {
        	Contact oneMember;
        	String requestKey = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        	if (requestKey.Contains ('@'))
        	{
	            oneMember = [select ID, Name, Membership_Type__c, Date_of_Birth__c, Phone, MobilePhone, Call_Opt_Out__c, Status__c, Email from Contact where email=:requestKey];
        	}
        	else
        	{
            	oneMember = [select ID, Name, Membership_Type__c, Date_of_Birth__c, Phone, MobilePhone, Call_Opt_Out__c, Status__c, Email from Contact where id=:requestKey];
        	}
            result += JSON.serialize(oneMember);
            RestContext.response.responseBody = Blob.valueOf (JSON.serialize(oneMember));
            RestContext.response.statusCode = 200;
        }
        catch (Exception e)
        {
            RestContext.response.responseBody = Blob.valueOf (JSON.serialize(new JSONError('MEMBER_NOT_FOUND', 'Member not found')));
            RestContext.response.statusCode = 404;
        }
	}   
}