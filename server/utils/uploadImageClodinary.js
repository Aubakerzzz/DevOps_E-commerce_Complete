import cloudinary from '../config/cloudinary.js';

const uploadImageClodinary = async(image)=>{
    const buffer = image?.buffer || Buffer.from(await image.arrayBuffer());

    const uploadImage = await new Promise((resolve, reject) => {
        cloudinary.uploader.upload_stream({ folder: "leyo" }, (error, uploadResult) => {
            if (error) return reject(error);
            return resolve(uploadResult);
        }).end(buffer);
    });

    return uploadImage;
}

export default uploadImageClodinary;