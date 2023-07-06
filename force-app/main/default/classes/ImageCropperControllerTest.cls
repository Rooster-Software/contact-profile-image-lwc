/**
 * @name ImageCropperControllerTest
 * @description Test Class for ImageCropperController class
 */ 
@isTest
private class ImageCropperControllerTest {
    @isTest
    static void getContentDocumentImageTest() {
        String base64String = 'VGVzdCBGaWxlIDI=';
        
        // save new image
        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode(base64String);
        cv.Title = 'InitialFile.jpg';
        cv.PathOnClient = 'InitialFile.jpg';
        insert cv;

        // get ContentDocument Id of the newly uploaded image file in Salesforce
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id LIMIT 1].ContentDocumentId;

        Test.startTest();
        String retrievedBase64String = ImageCropperController.getContentDocumentImage(contentDocumentId);
        Test.stopTest();

        Assert.areEqual(base64String, retrievedBase64String);
    }

    @isTest
    static void getContentDocumentImageErrorTest() {
        String base64String = 'VGVzdCBGaWxlIDI=';
        
        // save new image
        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode(base64String);
        cv.Title = 'InitialFile.jpg';
        cv.PathOnClient = 'InitialFile.jpg';
        insert cv;
        
        // create dummy account
        Account acc = new Account(Name = 'Test Acc');
        insert acc;

        Test.startTest();
        try {
            String retrievedBase64String = ImageCropperController.getContentDocumentImage(acc.Id);
        } catch (Exception e) {
            System.debug(e.getMessage());
            Assert.isInstanceOfType(e, System.AuraHandledException.class);
        }
        Test.stopTest();
    }
}