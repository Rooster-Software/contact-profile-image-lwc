/**
 * @name UploadImageModal
 * @description LWC designed to render as a modal and allow a user to upload and crop an image for use
 *  This LWC modal calls the imageCropper LWC to perform image uploading and cropping/scaling 
 */
import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class UploadImageModal extends LightningModal {
    @api label; // label is defined in component that opens this modal
    @api contentDocumentId; // Content Document Id of the existing photo (if there is one)
    @api croppieConfig; // config (options) for croppie component (shape and size of cropper)
    @api croppieImageConfig; // configuration of the preloaded image within Croppie (this is optional)
    @api imageMetadata; // metadata of the preloaded image if one is provided (this is optional)
    
    handleCancel() {
        // close the modal
        this.close('cancelled');
    }

    handleSave(event) {
        let croppieResult = event.detail;
        this.close(croppieResult); // close modal and pass croppieResult as modal close result
    }
}