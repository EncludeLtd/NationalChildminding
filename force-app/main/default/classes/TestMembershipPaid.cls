/*
Author: Eamon Kelly, Enclude
Purpose: When a membership payment is updated to Paid, set the contact to active and the Renewal Application Processed flag to true
*/
@isTest
private class TestMembershipPaid 
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
	
    static testMethod void testSetMembershipToPaid () 
    {
		TestConvertLead.TestLeadCreationExistingMemberWantingAnInvoice();
		Opportunity payment = [select StageName, npe01__Contact_Id_for_Role__c from Opportunity];
		payment.StageName = 'Paid';
		update payment;
		Contact member = [select ID, Status__c, Renewal_Applic_processed_in_Salesforce__c from Contact where ID=:payment.npe01__Contact_Id_for_Role__c limit 1];
		system.assertEquals ('Active', member.Status__c);
		system.assert (member.Renewal_Applic_processed_in_Salesforce__c);
    }
}