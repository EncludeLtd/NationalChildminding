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
	
Called from: Either the trigger or a button on the Lead page
Tested in: TestConvertLead 
*/
public with sharing class ConvertLead
{
	Lead memberLeadToConvert;
	public ConvertLead (ApexPages.StandardController controller)
    {
        memberLeadToConvert = (Lead)controller.getRecord();
     }
    
	public ConvertLead (Lead oneLead) // called from the before trigger (no need for update)
	{
		ConvertLeadCommon (oneLead);
	}
	
	public pageReference ConvertLeadNow () // called from the VF page ConvertMember
	{
		ConvertLeadCommon (memberLeadToConvert);
        update memberLeadToConvert;
        return new PageReference ('/' + memberLeadToConvert.id);
	}
	
	public Lead ConvertLeadCommon (Lead memberLead)
	{
       if (memberLead.Status.contains('Open'))
        {
        	Contact memberContact = CreateOrFindContact (memberLead);
        	if (memberContact != null)
        	{
        		UpdateContactFromFieldSetFields (memberLead, memberContact);
        		if (memberLead.Membership_new_renewals__c == 'NB' || memberLead.Membership_new_renewals__c == 'RNL')
	        	{
	        		if (memberLead.Membership_new_renewals__c == 'NB')
	        		{
	        			memberContact.Status__c = 'Application';
	        		}
	        		Opportunity payment = CreateSinglePayment (memberLead, memberContact);
	        		if (payment != null)
	        		{
	        			memberLead.Status = 'Closed - Converted';
	        		}
	        	}
       			update memberContact; // CreateSinglePayment may have set the status to Active 
        	}
        }
        else
        {
        	memberLead.Conversion_Error__c = 'Cannot convert an enquiry that is not Open';
        }
        return memberLead;
	} 
	
	public Contact CreateOrFindContact (Lead ld)
	{
        Contact member=null;
        if (isValid (ld.Membership_Number__c))
        {
        	try
        	{
        		member = [select ID, Status__c from Contact where Current_Member_Number__c	= :ld.Membership_Number__c limit 1];
        	}
        	catch (Exception e)
        	{
        		ld.Conversion_Error__c = 'Membership number does not match an existing member';
        		return null;
        	}
        }
        // renewals must use a membership number
        if (ld.Membership_new_renewals__c == 'RNL' && member == null)
        {
       		ld.Conversion_Error__c = 'Membership number must be provided for renewals';
       		return null;
        }
        if (member == null && isValid(ld.LastName) && isValid(ld.Email)) 
        {
        	try
        	{
        		member = [select ID, Status__c from Contact where Email = :ld.Email and LastName = :ld.LastName limit 1];
        	}
        	catch (Exception e)
        	{
         	}
        }
        if (member == null && isValid(ld.LastName) && isValidDate (ld.Birthdate__c))
        {
        	try
        	{
        		member = [select ID, Status__c from Contact where Date_of_Birth__c = :ld.Birthdate__c and LastName = :ld.LastName and Email = null limit 1];
        	}
        	catch (Exception e)
        	{
         	}
        }
        if (member == null && ld.Membership_new_renewals__c == 'NB')
        {
        	member = createContact (ld);
        }
        else if (member == null)
        {
        	ld.Conversion_Error__c = 'Member not found, please check last name, email or date of birth';
        } 
        else if (member.Status__c == 'Declined')
        {
        	ld.Conversion_Error__c = 'Member\'s status is currently Declined';
        	member = null;
        }
        else
        {
        	updateContact (member, ld);	
        }
        return member;
    }


	public Contact createContact (Lead newLead)
    {
    	ID clientRecordTypeID = [select Id from RecordType where DeveloperName = 'Client' and SObjectType = 'Contact' LIMIT 1].id;
        Contact newContact = new Contact (FirstName = isValid (newLead.FirstName)?newLead.FirstName:'',
            LastName=newLead.LastName, 
            Email=newLead.Email,
            Date_of_Birth__c = newLead.Birthdate__c,
            MailingStreet=isValid(newLead.Street)?newLead.Street:'',
            MailingCity=isValid(newLead.City)?newLead.City:'',
            MailingState=isValid(newLead.State)?newLead.State:'',
            MailingPostalCode=isValid(newLead.PostalCode)?newLead.PostalCode:'',
            MailingCountry=isValid(newLead.Country)?newLead.Country:'',
            LeadSource = newLead.LeadSource,
            RecordTypeId = clientRecordTypeID,
            Date_of_Initial_Contact__c = system.today(),
            ecass01__X4_Gender__c = isValid(newLead.Gender__c)?newLead.Gender__c:'',
            Contact_Nationality__c = isValid(newLead.Nationality__c)?newLead.Nationality__c:'',
            Contact_Nationality_Note__c = isValid(newLead.Nationality_Other_Specify__c)?newLead.Nationality_Other_Specify__c:'');
        
        insert newContact;  
        return newContact;
    }

    public Contact updateContact (Contact existingContact, Lead updatedLead)
    {
        if (isValid(updatedLead.Email)) existingContact.Email = updatedLead.Email;
        if (isValid(updatedLead.Street)) existingContact.MailingStreet = updatedLead.Street;
        if (isValid(updatedLead.City))  existingContact.MailingCity = updatedLead.City;
        if (isValid(updatedLead.State)) existingContact.MailingState = updatedLead.State;
        if (isValid(updatedLead.PostalCode)) existingContact.MailingPostalCode = updatedLead.PostalCode;
        if (isValid(updatedLead.Country)) existingContact.MailingCountry = updatedLead.Country;

        update existingContact; 
        return existingContact;
    }

	public Opportunity CreateSinglePayment (Lead ld, Contact cont)
    {
    	ID membershipRecordTypeID = [select Id from RecordType where DeveloperName = 'Membership' and SObjectType = 'Opportunity' LIMIT 1].id;
    	
        Opportunity payment = new Opportunity (Amount=ld.Amount__c, RecordTypeID=membershipRecordTypeID, CloseDate=system.today());
        payment.Name = cont.FirstName + ' ' + cont.LastName + ' - Membership ' + system.today().format();
        payment.AccountID = cont.AccountID;
		payment.npe01__Contact_Id_for_Role__c = cont.id;
		payment.LeadSource = ld.LeadSource;
		payment.Payment_Method__c = ld.Payment_Method__c;
		payment.Type = 'Membership with Ins';
		payment.Membership_New_Renewal__c = ld.Membership_new_renewals__c;
		payment.Debit_Card_Charge__c = ld.Debit_Card_Charge__c;
		payment.Credit_Card_Charge__c = ld.Credit_Card_Charge__c;
		payment.Insurance_Amount__c = ld.Insurance_Amount__c;
		payment.CMI_Membership_Amount__c = ld.CMI_Membership_Amount__c;
		payment.Current_Member_Number__c = ld.Membership_Number__c;
		if (ld.Payment_Method__c == 'Online' && (ld.Processing_Status__c == 'Process' || ld.Processing_Status__c == 'Hold With Pay' ))
		{
			payment.StageName='Paid';
			payment.Online_Payt_Transaction_ID__c = ld.Online_Payt_Transaction_ID__c;
			cont.Renewal_Applic_processed_in_Salesforce__c = true;
   			cont.Status__c = 'Active';
 			payment.npe01__Membership_Start_Date__c = ld.Membership_Start_Date__c;
			payment.npe01__Membership_End_Date__c = ld.Membership_End_Date__c;
		}
		else 
		{
			payment.StageName='Invoice';
		}
		insert payment;
        return payment;
    }
    
    public void UpdateContactFromFieldSetFields (Lead ld, Contact member)
    {
   		List<Schema.FieldSetMember> leadFields = getFields ('MappingFields', true);
   		List<Schema.FieldSetMember> contactFields = getFields ('MappingFields', false);
     	
     	Lead leadMember;
     	if (ld.id == null)
     	{
     		leadMember = ld; // called from before trigger so all fields available
     	}
     	else
     	{
	    	// need to create an SOQL statement with all the fields
	   		String sQuery = 'select ID ';
	   		for (Integer i=0; i<leadFields.size(); i++)
		    {
	   			sQuery += ', ' + leadFields[i].getFieldPath();
		    }
		    sQuery += ' from Lead where id= \'' + ld.id + '\' limit 1';
		    leadMember = dataBase.Query (sQuery);
     	}
	    for (Integer i=0; i<leadFields.size(); i++)
	    {
	    	try
	    	{
	    		String contactfieldName = contactFields[i].getFieldPath().replace('ConvertedContact.','');
	    		String leadFieldName = leadFields[i].getFieldPath();
				Schema.DisplayType fieldType = leadFields[i].getType();
    			if (fieldType == DisplayType.Date && isValidDate((Date)(leadMember.get(leadFieldName))))
    			{
	    			member.put(contactFieldName, (Date)(leadMember.get(leadFieldName)));
   				}
		    	else if ((fieldType == DisplayType.Double || fieldType == DisplayType.Currency) && isValidDecimal((Decimal)(leadMember.get(leadFieldName))))
			    {
	    			member.put(contactFieldName, (Decimal)(leadMember.get(leadFieldName)));
   				}
		    	else if (fieldType == DisplayType.Boolean)
		    	{
    				Schema.DisplayType destFieldType = contactFields[i].getType();
    				if (destFieldType == DisplayType.Boolean) member.put(contactFieldName, (Boolean)(leadMember.get(leadFieldName)));
    				else member.put(contactFieldName, (Boolean)(leadMember.get(leadFieldName))?1:0);
		    	}
	    		else if (isValid((String)(leadMember.get(leadFieldName)))) 
	    		{
			    	member.put(contactFieldName, (String)(leadMember.get(leadFieldName)));
	    		}
	    	}
	     	catch (Exception e)
	    	{
	    		ld.Conversion_Error__c += e.getMessage();
	    	}
	    }	    		
    }
    
 	public List<Schema.FieldSetMember> getFields(String fieldSetName, Boolean bLeadFields) 
    {
    	System.Debug ('Fieldset name is ' + fieldSetName);
    	Schema.FieldSet fs1 = Schema.SObjectType.Lead.fieldSets.getMap().get(fieldSetName);
    	List<Schema.FieldSetMember> allFields = fs1.getFields();
     	List<Schema.FieldSetMember> returnFields = new List<Schema.FieldSetMember>();
    	
    	Integer start = bLeadFields ? 0:1;
    	for (Integer i=start; i<allFields.size(); i+=2)
    	{
			returnFields.add (allFields[i]);    		
    	}
    	return returnFields;
    }
    
    public static boolean isValid (String text)
    {
        if (text <> null && text <> '' && text <> '[not provided]' && text <> 'null') return true;
        else return false;
    }

	public boolean isValidDate (Date text)
	{
		if (text <> null) return true;
		else return false;
	}

	public static boolean isValidDecimal (Decimal text)
	{
		if (text <> null) return true;
		else return false;
	}
}