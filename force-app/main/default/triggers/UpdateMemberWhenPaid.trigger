/*
Author: Eamon Kelly, Enclude
Purpose: When a membership payment is updated to Paid, set the contact to active and the Renewal Application Processed flag to true
Tested in: TestMembershipPaid
*/
trigger UpdateMemberWhenPaid on Opportunity (after update) 
{
   	ID membershipRecordTypeID = [select Id from RecordType where DeveloperName = 'Membership' and SObjectType = 'Opportunity' LIMIT 1].id;
   	set <ID> membersToUpdate = new set <ID>(); 
	for (Opportunity newOpp : trigger.new)
	{
		if (newOpp.RecordTypeID == membershipRecordTypeID && newOpp.StageName == 'Paid')
		{
			Opportunity oldOpp = trigger.oldMap.get (newOpp.id);
			if (oldOpp != null && oldOpp.StageName != 'Paid')
			{
				membersToUpdate.add (newOpp.npe01__Contact_Id_for_Role__c);
			}
		}
	}
    if (membersToUpdate.size() > 0)
    {
    	list<Contact> members = [select ID, Renewal_Applic_processed_in_Salesforce__c, Status__c from Contact where ID in :membersToUpdate];
    	for (Contact oneMember : members)
    	{
    		oneMember.Renewal_Applic_processed_in_Salesforce__c = true;
    		oneMember.Status__c = 'Active';
    	}
    	if (members.size() > 0) update members;
    }
}