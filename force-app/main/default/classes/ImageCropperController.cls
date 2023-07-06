/**
 * @name ImageCropperController
 * @author Rooster Software LLC
 * @description Controller class for imageCropper LWC
 */
public with sharing class ImageCropperController {
    /**
     * Get an image's raw file as a Base64 encoded string
     * This method assumes that the provided Id is that of a ContentDocument whose content is an image
     * 
     * @name    getContentDocumentImage
     * @param   recordId            record id of the ContentDocument to be retrieved
     * @return  String              return the base64 encoded value of the VersionData of the content
     */
    @AuraEnabled(cacheable=true)
    public static String getContentDocumentImage(Id recordId){
        try {
            ContentVersion cv = [SELECT Id, VersionData FROM ContentVersion WHERE IsLatest = true AND ContentDocumentId =: recordId LIMIT 1];
            return EncodingUtil.base64Encode(cv.VersionData);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}