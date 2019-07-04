/*
Author: Eamon Kelly, Enclude
Purpose: Test the REST services
*/
@isTest
private class TestRestServices 
{
	@testSetup static void CreateMember ()
	{
		Contact twoMember = new Contact (FirstName='Mary', LastName='Jones', email='jones@test.com', Current_Member_Number__c='1234', Status__c='Active', Display_advert_on_web_site__c=true, Text_for_advert__c='Some more text');
		insert twoMember;	
		Contact threeMember = new Contact (FirstName='Ann', LastName='Jones', Date_of_Birth__c=Date.newInstance(1980, 2, 3), Current_Member_Number__c='12346', Status__c='Active', Display_advert_on_web_site__c=true, Text_for_advert__c='Some text');
		insert threeMember;	
		Contact declinedMember = new Contact (FirstName='Ann', LastName='Declined', Date_of_Birth__c=Date.newInstance(1980, 2, 3), Current_Member_Number__c='12345', Status__c = 'Declined');
		insert declinedMember;	
	}

    static testMethod void getMemberTest() 
    {
    	ID memberID = [select ID from Contact where email='jones@test.com'].id;
	    RestRequest req = new RestRequest(); 
	    RestResponse res = new RestResponse();

	    req.requestURI = 'https://ncmi--mem.cs87.my.salesforce.com/services/apexrest/member/'+ memberID;

	    req.addHeader('Content-Type', 'application/json');
    	req.httpMethod = 'GET';
    	req.requestBody = Blob.valueof('{}');

	    RestContext.request = req;
    	RestContext.response= res;


	    Test.startTest();
	    MemberRestService.getMember();
	    Test.stopTest();
        
    	System.assertEquals(200, res.statusCode);
    }
    
    static testMethod void getMemberFailTest() 
    {
	    RestRequest req = new RestRequest(); 
	    RestResponse res = new RestResponse();

	    req.requestURI = 'https://ncmi--mem.cs87.my.salesforce.com/services/apexrest/member/1234';

	    req.addHeader('Content-Type', 'application/json');
    	req.httpMethod = 'GET';
    	req.requestBody = Blob.valueof('{}');

	    RestContext.request = req;
    	RestContext.response= res;


	    Test.startTest();
	    MemberRestService.getMember();
	    Test.stopTest();
        
    	System.assertEquals(404, res.statusCode);
    }
    
    static testMethod void testMemberChangeMobile ()
    {
    	ID memberID = [select ID from Contact where email='jones@test.com'].id;
	    RestRequest req = new RestRequest(); 
	    RestResponse res = new RestResponse();

	    req.requestURI = 'https://ncmi--mem.cs87.my.salesforce.com/services/apexrest/member/'+ memberID;

	    req.addHeader('Content-Type', 'application/json');
    	req.httpMethod = 'POST';
    	req.requestBody = Blob.valueof('{}');

	    RestContext.request = req;
    	RestContext.response= res;


	    Test.startTest();
    	MemberRestService.updateMemberDetails (memberID, '123456');
	    Test.stopTest();
        
    	System.assertEquals(200, res.statusCode);
    	String mobile = [select MobilePhone from Contact where email='jones@test.com'].MobilePhone;
    	System.assertEquals ('123456', mobile);
    }
    
    static testMethod void getAdvertsTest() 
    {
	    RestRequest req = new RestRequest(); 
	    RestResponse res = new RestResponse();

	    req.requestURI = 'https://ncmi--mem.cs87.my.salesforce.com/services/apexrest/adverts';

	    req.addHeader('Content-Type', 'application/json');
    	req.httpMethod = 'GET';
    	req.requestBody = Blob.valueof('{}');

	    RestContext.request = req;
    	RestContext.response= res;


	    Test.startTest();
	    AdvertsRestService.getAdverts();
	    Test.stopTest();
        
    	System.assertEquals(200, res.statusCode);
    }
    
}