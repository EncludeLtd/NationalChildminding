/*
Author: Eamon Kelly, Enclude
Purpose: Three types of leads are supported - a member application form, a renewal form and a change request form.
	A contact record will be created or updated and an opportunity record created (for application forms and renewal forms)
	The fields to copy will be in fieldsets
	Matching will be on:
		1) Membership number - if given and does not match, fail
		2) Last name and email
		3) Last name and date of birth - only use if the email field on the existing contact is blank
	Error messages will accumulate
	This code will not need to handle more than one lead at a time
	
Tested in: TestConvertLead 
*/
trigger NewLeadReceived on Lead (before insert) 
{
	for (Lead oneLead : trigger.new)
	{
		if (oneLead.Processing_Status__c == 'Process')
		{
			ConvertLead cl = new ConvertLead (oneLead);
		}
	}    
}