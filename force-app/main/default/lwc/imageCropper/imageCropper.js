/**
 * @name ImageCropper
 * @description LWC implementing Croppie (third-party JS library) for scaling and resizing image
 *  Croppie library: https://github.com/foliotek/croppie
 */
import { LightningElement, api } from 'lwc';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import cropCss from '@salesforce/resourceUrl/croppieCss';
import cropJS from '@salesforce/resourceUrl/croppieJs';
import getContentDocumentImage from '@salesforce/apex/ImageCropperController.getContentDocumentImage';

export default class ImageCropper extends LightningElement {
    croppieLoaded = false; // indicates if croppie JS/CSS libraries have been loaded by component
    disableDelete = true; // controls if the Delete (Remove Image) button is disabled
    disableSave = true; // controls if the Save image button is disabled
    isLoading = true; // indicates if spinner should be shown or hidden
    croppieFileReader; // the Croppie file reader and image cropper
    originalFileData; // copy of the original base64 encoded image file before manipulation with croppie
    _imageId; // variable used to store the Content Document Id of the existing image (if one exists)

    @api croppieConfig;
    @api imageConfig; // this is the preexisting or newly loaded image file

    // imageId is the Content Document Id of the existing photo (if there is one)
    @api 
    get imageId() {
        return this._imageId;
    }
    
    set imageId(value) {
        this._imageId = value;
    }

    // return the file size in mb
    get fileSize() {
        return this.imageConfig.size / 1000000;
    }

    // return true if there is no file loaded
    get isFileNull() {
        return this.imageConfig ? false : true;
    }

    connectedCallback() {
        Promise.all([
            loadStyle(this, cropCss),
            loadScript(this, cropJS)
        ]).then(() => {
            // initialize component
            this.croppieLoaded = true;
            if (this._imageId) { // check if image already exists
                this.loadImage();
            } else {
                this.isLoading = false;
            }
        }).catch((error) => {
            // handle error
            console.log('error loading Croppie');
            console.log(JSON.stringify(error));
        });
    }

    // create file object from URL
    createImageFileFromURL(url, type){
        // TODO : In order to avoid "Tainted Canvas" issue if/when loading image from an external URL, 
        //  implement a custom web-server with acceptable CORS to load and host the image for Croppie to reference
        //  see https://github.com/Foliotek/Croppie/issues/407 for Tainted Canvas issue suggested solution by Croppie devs
    }

    // handle deletion/removal of the file
    handleDelete(event) {
        // destroy croppie instance
        this.croppieFileReader.destroy();
        
        // set file value to null
        this.imageConfig = null;

        this.disableDelete = true; // disable delete button
        this.disableSave = false; // enable the save button in case the user wants to save after removing the preexisting image
    }

    handleFileChange(event) {
        this.imageConfig = event.target.files[0];
        console.log(this.imageConfig);
        var reader = new FileReader();
        reader.onload = () => {
            this.initializeCroppie();

            console.log('file url...');
            console.log(reader.result);

            this.originalFileData = reader.result.split(',')[1]; // save the original file

            this.croppieFileReader.bind({
                url: reader.result
            });
        };

        reader.readAsDataURL(this.imageConfig);

        this.disableDelete = false; // enable delete button
        this.disableSave = false; // enable save button
    }

    // handle saving of the cropped image
    handleSave(event) {
        // get image result from croppie
        let croppieConfig = this.croppieFileReader.get();
        console.log('croppie config');
        console.log(JSON.stringify(croppieConfig));
        
        this.croppieFileReader.result({
            type : 'base64',
            circle : false
        }).then(croppieResult => {
            // destroy Croppie
            this.croppieFileReader.destroy();

            // pass image to parent
            this.dispatchEvent(new CustomEvent('save', { detail : {
                file            : this.imageConfig, // the file object from the lightning-input (type='file') component
                originalImage   : this.originalFileData, // the original image encoded in base64
                croppieConfig   : croppieConfig, // these are the croppie configurations applied to the originalImage
                croppedImage    : croppieResult.split(',')[1] // cropped image after croppie manipulations applied to originalImage, encoded in base64
            }}));
        }).catch(error => {
            console.log('croppie result error...');
            console.log(error);
        });
    }

    initializeCroppie() {
        this.croppieFileReader = new Croppie(this.template.querySelector('[data-id="croppie"]'), {
            viewport : {
                width : 300,
                height : 300,
                type : 'square'
            },
            boundary : {
                width : 400,
                height : 400
            },
            showZoomer : true,
        });
    }

    // load existing image stored in ContentDocument in Salesforce and bind image to Croppie
    loadImage() {
        // get raw file data of image provided to component
        getContentDocumentImage({ recordId : this._imageId }).then(result => {
            this.originalFileData = result; // this is the raw, base64 encoded image string saved in the ContentDocument in Salesforce
            let fileUrl = 'data:' + this.imageConfig.type + ';base64,' + this.originalFileData;

            // bind the image to Croppie
            if (this.croppieFileReader) { // if croppie has been initialized, destroy it and create a new one
                this.croppieFileReader.destroy();
            }

            setTimeout(() => {
                this.initializeCroppie();
                this.croppieFileReader.bind({
                    url         : fileUrl, //'/sfc/servlet.shepherd/document/download/' + this._imageId,
                    points      : this.croppieConfig.points,
                    zoom        : this.croppieConfig.zoom,
                    orientation : this.croppieConfig.orientation
                });
                this.disableDelete = false;
                this.disableSave = false;
                this.isLoading = false;
            }, 500);
        }).catch(error => {
            console.log('error with getContentDocumentImage');
            console.log(JSON.stringify(error));
        });
    }
}