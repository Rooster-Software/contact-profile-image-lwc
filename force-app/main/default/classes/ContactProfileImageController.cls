/**
 * @name ContactProfilePhotoController
 * @author Rooster Software LLC
 * @description Controller for contactProfilePhoto LWC containing methods for retrieving and saving a Contact record "profile photo"
 */
public with sharing class ContactProfileImageController {
    /**
     * Method to delete the profile image of a Contact record. This method
     * deletes the ContentDocument and clears the reference to the ContentDocument on the Contact record.
     * 
     * @name    deleteProfileImage
     * @param   recordId            record id of the Contact record to remove the profile image from
     * @return  Contact             return the Contact record with the image and image config fields nullified
     */
    private static Contact deleteProfileImage(Contact con){
        // delete ContentDocument
        if (!String.isBlank(con.ProfileImageDocumentId__c)) {
            delete new ContentDocument(Id = con.ProfileImageDocumentId__c);
        }

        // nullify image fields on contact
        con.ProfileImageDocumentId__c = null;
        con.ProfileImageMetadata__c = null;
        return con;
    }
    
    /**
     * This method accepts a Contact recordId and a base64 encoded image
     * This method saves the image as a File (ContentDocument) and links the image to the Contact record
     * 
     * @name    saveProfileImage
     * @param   recordId            record id of the Contact record the image is being saved to
     * @param   base64Image         image to be saved encoded as a base64 string
     * @param   file                JSON string representing image file being loaded
     * @return  String              ContentDocument Id of the ContentDocument storing the newly loaded image
     */
    @AuraEnabled
    public static String saveProfileImage(Id recordId, String base64Image, String file){
        try {
            Id contentDocumentId; // Id of the ContentDocument to be created for the new image

            // get contact record
            Contact con = [SELECT Id, Name, ProfileImageDocumentId__c FROM Contact WHERE Id =: recordId LIMIT 1];
            deleteProfileImage(con); // delete previous image

            if (base64Image != null && file != null) { // check if new image is provided
                System.debug(file);
                Map<String,Object> imgFileMap = (Map<String,Object>) JSON.deserializeUntyped(file);
                System.debug(imgFileMap);

                // save new image
                ContentVersion cv = new ContentVersion();
                cv.VersionData = EncodingUtil.base64Decode(base64Image);
                cv.Title = String.valueOf(imgFileMap.get('name'));
                cv.PathOnClient = String.valueOf(imgFileMap.get('name'));
                insert cv;

                // get ContentDocument Id of the newly uploaded image file in Salesforce
                contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id LIMIT 1].ContentDocumentId;

                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = contentDocumentId;
                cdl.LinkedEntityId = recordId;
                // ShareType is either 'V', 'C', or 'I'
                // V = Viewer, C = Collaborator, I = Inferred
                cdl.ShareType = 'V';
                insert cdl;

                con.ProfileImageDocumentId__c = contentDocumentId;
                con.ProfileImageMetadata__c = file;
            }

            update con; // save contact record

            return contentDocumentId; // return the new ContentDocumentId;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}