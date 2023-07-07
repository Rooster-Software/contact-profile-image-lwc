/**
 * @name ContactProfilePhotoControllerTest
 * @author Rooster Software LLC
 * @description Test class for ContactProfilePhotoController
 */
@isTest
private class ContactProfileImageControllerTest {
    @isTest
    static void saveProfileImageTest() {
        Account testManagerAcc = new Account(Name = 'Test Property Managers, Inc.');
        insert testManagerAcc;

        // save new image
        ContentVersion cv = new ContentVersion();
        cv.VersionData = Blob.valueOf('Test Image 2');
        cv.Title = 'InitialFile.jpg';
        cv.PathOnClient = 'InitialFile.jpg';
        insert cv;

        // get ContentDocument Id of the newly uploaded image file in Salesforce
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id LIMIT 1].ContentDocumentId;
        String file = '{"name":"2018-tesla-model-3-performance-1545165726.jpg","size":1260905,"type":"image/jpeg","lastModified":1562910615362}';
        
        Contact testCon = new Contact(
            FirstName = 'Harry', 
            LastName = 'Style',
            AccountId = testManagerAcc.Id
        );
        testCon.ProfileImageDocumentId__c = contentDocumentId;
        testCon.ProfileImageMetadata__c = file;
        insert testCon;

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = contentDocumentId;
        cdl.LinkedEntityId = testCon.Id;
        // ShareType is either 'V', 'C', or 'I'
        // V = Viewer, C = Collaborator, I = Inferred
        cdl.ShareType = 'V';
        insert cdl;

        String base64EncodedImage = EncodingUtil.base64Encode(Blob.valueOf('Test Image'));
        String newFile = '{"name":"2018-tesla-model-3-performance-1545165726.jpg","size":1260903,"type":"image/jpeg","lastModified":1562910700000}';

        Test.startTest();
        ContactProfileImageController.saveProfileImage(testCon.Id, base64EncodedImage, newFile);
        Test.stopTest();

        Contact updatedCon = [SELECT Id, Name, ProfileImageDocumentId__c, ProfileImageMetadata__c FROM Contact WHERE Id =: testCon.Id LIMIT 1];

        Assert.isNotNull(updatedCon.ProfileImageDocumentId__c);
        Assert.areNotEqual(contentDocumentId, updatedCon.ProfileImageDocumentId__c);
        Assert.areNotEqual(file, updatedCon.ProfileImageMetadata__c);
    }

    @isTest
    static void deleteProfileImageTest() {
        Account testManagerAcc = new Account(Name = 'Test Property Managers, Inc.');
        insert testManagerAcc;

        // save new image
        ContentVersion cv = new ContentVersion();
        cv.VersionData = Blob.valueOf('Test Image 2');
        cv.Title = 'InitialFile.jpg';
        cv.PathOnClient = 'InitialFile.jpg';
        insert cv;

        // get ContentDocument Id of the newly uploaded image file in Salesforce
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id LIMIT 1].ContentDocumentId;
        String base64EncodedImage = EncodingUtil.base64Encode(Blob.valueOf('Test Image'));
        String file = '{"name":"2018-tesla-model-3-performance-1545165726.jpg","size":1260905,"type":"image/jpeg","lastModified":1562910615362}';
        
        Contact testCon = new Contact(
            FirstName = 'Harry', 
            LastName = 'Style',
            AccountId = testManagerAcc.Id
        );
        testCon.ProfileImageDocumentId__c = contentDocumentId;
        testCon.ProfileImageMetadata__c = file;
        insert testCon;

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = contentDocumentId;
        cdl.LinkedEntityId = testCon.Id;
        // ShareType is either 'V', 'C', or 'I'
        // V = Viewer, C = Collaborator, I = Inferred
        cdl.ShareType = 'V';
        insert cdl;        

        Test.startTest();
        ContactProfileImageController.saveProfileImage(testCon.Id, null, null); // set base64String and file parameters to null indicates the profile image being saved is null (the previous profile image is being removed)
        Test.stopTest();

        Contact updatedCon = [SELECT Id, Name, ProfileImageDocumentId__c, ProfileImageMetadata__c FROM Contact WHERE Id =: testCon.Id LIMIT 1];

        Assert.isNull(updatedCon.ProfileImageDocumentId__c);
        Assert.isNull(updatedCon.ProfileImageMetadata__c);
    }

    @isTest
    static void saveProfileImageErrorTest() {
        Account testManagerAcc = new Account(Name = 'Test Property Managers, Inc.');
        insert testManagerAcc;

        // save new image
        ContentVersion cv = new ContentVersion();
        cv.VersionData = Blob.valueOf('Test Image 2');
        cv.Title = 'InitialFile.jpg';
        cv.PathOnClient = 'InitialFile.jpg';
        insert cv;

        // get ContentDocument Id of the newly uploaded image file in Salesforce
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id LIMIT 1].ContentDocumentId;
        String file = '{"name":"2018-tesla-model-3-performance-1545165726.jpg","size":1260905,"type":"image/jpeg","lastModified":1562910615362}';
        
        Contact testCon = new Contact(
            FirstName = 'Harry', 
            LastName = 'Style',
            AccountId = testManagerAcc.Id
        );
        testCon.ProfileImageDocumentId__c = contentDocumentId;
        testCon.ProfileImageMetadata__c = file;
        insert testCon;

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = contentDocumentId;
        cdl.LinkedEntityId = testCon.Id;
        // ShareType is either 'V', 'C', or 'I'
        // V = Viewer, C = Collaborator, I = Inferred
        cdl.ShareType = 'V';
        insert cdl;
        
        Test.startTest();
        try {
            ContactProfileImageController.saveProfileImage(testCon.Id, 'badImageVal', 'badFileVal');
        } catch (Exception e) {
            System.debug(e.getMessage());
            Assert.isInstanceOfType(e, System.AuraHandledException.class);
        }
        Test.stopTest();
    }
}