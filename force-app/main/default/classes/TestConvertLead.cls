/*
Author: Eamon Kelly, Enclude
Purpose: When a lead is created find or create a contact and create an opportunity record
*/
@isTest
public class TestConvertLead 
{
	@testSetup static void CreateMember ()
	{
		Contact oneMember = new Contact (FirstName='Mary', LastName='Smith', email='mary@test.com');
		insert oneMember;	
		Contact twoMember = new Contact (FirstName='Mary', LastName='Jones', email='jones@test.com', Current_Member_Number__c='1234');
		insert twoMember;	
		Contact threeMember = new Contact (FirstName='Ann', LastName='Jones', Date_of_Birth__c=Date.newInstance(1980, 2, 3), Current_Member_Number__c='12346');
		insert threeMember;	
		Contact declinedMember = new Contact (FirstName='Ann', LastName='Declined', Date_of_Birth__c=Date.newInstance(1980, 2, 3), Current_Member_Number__c='12345', Status__c = 'Declined');
		insert declinedMember;	
	}
	
	static testmethod void TestLeadCreationNewMember ()
	{
		Lead ld1 = new Lead (FirstName='Fred', LastName='Smith', company='Self', email='from@test.com', Phone='0857130794', Membership_new_renewals__c = 'NB', LeadSource='Web', 
			Payment_Method__c='Online', Amount__c = 155, Online_Payt_Transaction_ID__c='1234', Status='Open', Processing_Status__c = 'Hold With Pay');
		insert ld1;

		ApexPages.StandardController sc = new ApexPages.StandardController (ld1);
		ConvertLead cl = new ConvertLead (sc);
		cl.ConvertLeadNow();
		
		Contact cont = [select Id, FirstName from Contact where email='from@test.com'];
		system.assertEquals ('Fred', cont.FirstName);

		Opportunity payment = [select Amount from Opportunity];
		system.assertEquals (155, payment.Amount);
	}
	
	static testmethod void TestLeadCreationExistingMember ()
	{
		Lead ld1 = new Lead (FirstName='Mary', LastName='Jones', company='Self', email='jones@test.com', Phone='0857130794', Membership_new_renewals__c = 'NB', LeadSource='Web', 
			Payment_Method__c='Online', Amount__c = 155, Online_Payt_Transaction_ID__c='1234', Status='Open', Processing_Status__c = 'Process', Membership_Number__c='1234');
		insert ld1;

		Contact cont = [select Id, FirstName from Contact where Phone='0857130794'];
		system.assertEquals ('Mary', cont.FirstName);

		Opportunity payment = [select Amount from Opportunity];
		system.assertEquals (155, payment.Amount);
	}

	static testmethod public void TestLeadCreationExistingMemberWantingAnInvoice ()
	{
		Lead ld1 = new Lead (FirstName='Ann', LastName='Jones', company='Self', email='annjones@test.com', Phone='0857130794', Membership_new_renewals__c = 'RNL', LeadSource='Web', 
			Payment_Method__c='Online', Amount__c = 155, Online_Payt_Transaction_ID__c='1234', Status='Open', Processing_Status__c = 'Hold and No Pay', Birthdate__c=Date.newInstance (1980, 2, 3),
			Membership_Number__c='12346');
		insert ld1;

		ApexPages.StandardController sc = new ApexPages.StandardController (ld1);
		ConvertLead cl = new ConvertLead (sc);
		cl.ConvertLeadNow();
		
		Contact cont = [select Id, FirstName from Contact where Phone='0857130794'];
		system.assertEquals ('Ann', cont.FirstName);

		Opportunity payment = [select StageName from Opportunity];
		system.assertEquals ('Invoice', payment.StageName);
	}

	static testmethod void TestLeadCreationExistingDeclinedMember ()
	{
		Lead ld1 = new Lead (FirstName='Ann', LastName='Declined', company='Self', Membership_new_renewals__c = 'RNL', LeadSource='Web', Phone='0857130794', 
			Payment_Method__c='Online', Amount__c = 155, Online_Payt_Transaction_ID__c='1234', Status='Open', Processing_Status__c = 'Process', Membership_Number__c='12345');
		insert ld1;
		
		Contact cont = [select Id, Phone from Contact where LastName='Declined'];
		system.assertEquals (null, cont.Phone); // phone number not updated

		list <Opportunity> payments = [select StageName from Opportunity];
		system.assertEquals (0, payments.size()); // no payments created
		
		Lead ldResult = [select Conversion_Error__c from Lead];
		system.assert (ldResult.Conversion_Error__c.contains('Declined'));
	}
}