const cloudinary = require('cloudinary').v2;


/**
 * Configure Cloudinary with environment variables
 */
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
  secure: true
});

/**
 * Generate a signed upload signature for client-side uploads
 * This prevents exposing the API_SECRET to the mobile app.
 * @param {string} folder - The folder to upload into (e.g., 'users/123/kyc')
 * @param {string} publicId - Optional specific filename
 */
exports.generateSignature = (folder, publicId = null) => {
  const timestamp = Math.round(new Date().getTime() / 1000);
  
  const params = {
    timestamp: timestamp,
    folder: `kaamkaaz/${folder}`,
    // Set some security constraints in the signature
    transformation: 'q_auto,f_auto'
  };

  if (publicId) {
    params.public_id = publicId;
  }

  // Generate the signature using the API_SECRET (only on backend)
  const signature = cloudinary.utils.api_sign_request(
    params,
    process.env.CLOUDINARY_API_SECRET
  );

  return {
    signature,
    timestamp,
    cloudName: process.env.CLOUDINARY_CLOUD_NAME,
    apiKey: process.env.CLOUDINARY_API_KEY,
    folder: params.folder,
    publicId: params.public_id
  };
};

/**
 * Delete an image from Cloudinary by its Public ID
 */
exports.deleteImage = async (publicId) => {
  if (!publicId) return null;
  try {
    return await cloudinary.uploader.destroy(publicId);
  } catch (err) {
    console.error('Cloudinary Delete Error:', err.message);
    return null;
  }
};

/**
 * Validate if a file type is allowed
 */
exports.isValidImageType = (mimetype) => {
  const allowed = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
  return allowed.includes(mimetype);
};

/**
 * Sanitize filename to prevent directory traversal or malicious characters
 */
exports.sanitizeFilename = (filename) => {
  return filename.replace(/[^a-z0-9]/gi, '_').toLowerCase();
};
