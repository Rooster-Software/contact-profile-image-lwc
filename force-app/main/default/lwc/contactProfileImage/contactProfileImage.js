/**
 * @name ContactProfileImage
 * @description LWC to display a profile photo for a contact. This component is housed on the Contact lightning record page
 *  This component allows a user w/ edit access to the Contact record to upload a profile image
 *  This component allows a user to remove or replace the current profile image.
 */
import { LightningElement, api, wire } from 'lwc';
import UploadImageModal from 'c/uploadImageModal'; // lightning modal

import saveProfileImage from '@salesforce/apex/ContactProfileImageController.saveProfileImage';

import { getRecord, getFieldValue, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import PROFILE_PHOTO_ID_FIELD from '@salesforce/schema/Contact.ProfileImageDocumentId__c';
import PROFILE_PHOTO_METADATA_FIELD from '@salesforce/schema/Contact.ProfileImageMetadata__c';

export default class ContactProfileImage extends LightningElement {
    @api recordId; // record id of the Contact record
    
    isLoading = false; // indicates if component is loading, saving, or rendering

    @wire(getRecord, { recordId : '$recordId', fields : [PROFILE_PHOTO_ID_FIELD, PROFILE_PHOTO_METADATA_FIELD] })
    contact;
    
    get contentDocumentId() { // id of the contact profile image file (ContentDocument)
        return getFieldValue(this.contact.data, PROFILE_PHOTO_ID_FIELD);
    }

    get imageMetadata() {
        return JSON.parse(getFieldValue(this.contact.data, PROFILE_PHOTO_METADATA_FIELD));
    }

    get hasProfileImage() {
        let profilePhotoId = getFieldValue(this.contact.data, PROFILE_PHOTO_ID_FIELD);
        if (profilePhotoId) {
            return true;
        }
        return false;
    }
    
    get profileImageSrc() {
        return '/sfc/servlet.shepherd/document/download/' + getFieldValue(this.contact.data, PROFILE_PHOTO_ID_FIELD);
    }

    async handleUpload() {
        // load uploadImageModal LWC modal
        // if modal closed with X button, promise returns result = 'undefined'
        // if modal closed with OK button, promise returns result = 'okay'
        const imageLoadResult = await UploadImageModal.open({
            label : 'Upload Contact Profile Image',
            size : 'full',
            description : 'Upload, crop and scale Contact profile image',
            contentDocumentId : this.contentDocumentId,
            croppieConfig : {
                viewport : {
                    width : 199,
                    height : 199,
                    type : 'circle'
                },
                boundary : {
                    width : 200,
                    height : 200
                },
                showZoomer : true,
            },
            croppieImageConfig : null,   // if applying a saved Croppie Configuration to an image, provide croppie configuration JSON object here
                                    // An example Croppie Configuration JSON object is {"points":["562","570","2847","2855"],"zoom":0.1313,"orientation":1}
                                    // This object is obtained by running 'get()' on the croppie object in JS
            imageMetadata : this.imageMetadata  // An imageMetadata is a JSON object with the following structure: {"name":"PXL_20220120_153809222-min.jpg","size":1458447,"type":"image/jpeg","lastModified":1658936557814}
                                // An imageMetadata contains metadata about the provided image
                                // This metadata may be valuable when rendering a stored image using Croppie, but it needs to be constructed and stored when saving the image
        });
        // if user clicks on X button, do nothing
        if (imageLoadResult) { // if user completes file upload
            // evaluate result and update the Contact record with the new profile image
            if (imageLoadResult != 'cancelled') {
                this.saveProfileImage(imageLoadResult);
            }
        }
    }

    // method to create a replacement JSON object of image metadata
    replaceFile(file) {
        let newFileObj = {
            name : file.name,
            size : file.size,
            type : file.type,
            lastModified : file.lastModified
        };
        return newFileObj;
    }

    // saveProfileImage: accept Croppie result and save profile image to Contact record
    //  imageResult contains JSON object from handleSave method in imageCropper component
    //  imageResult structure:
    //      - file              reference to the JSON file object from the lightning-input (type='file') component
    //                              if saving image metadata as a String, run JSON.stringify(this.replaceFile(imageResult.file));
    //      - originalImage     the original image encoded as a base64 string
    //      - croppieImageConfig     these are the croppie configurations applied to the originalImage, this is a JSON object
    //      - croppedImage      cropped image after croppie manipulations applied to originalImage, encoded as base64 string
    saveProfileImage(imageResult) {
        this.isLoading = true; // turn on spinner
        
        let fileMetadata = imageResult.file ? JSON.stringify(this.replaceFile(imageResult.file)) : null;

        saveProfileImage({ 
            recordId            : this.recordId,
            base64Image         : imageResult.croppedImage,
            file                : fileMetadata
        }).then(() => {
            // TODO : rerender component to show latest image
            notifyRecordUpdateAvailable([{ recordId : this.recordId }]).then(() => {
                this.isLoading = false; // turn off spinner
            });
        }).catch(error => {
            console.log('contactProfileImage:saveProfileImage error...');
            console.log(error);
        });
    }
}