/**
 * Utility functions for handling images and media
 */

// Đã thêm /files/ vào trước các ảnh mặc định (giả định các ảnh này cũng nằm ở Backend)
const DEFAULT_IMAGE_URL = `${process.env.REACT_APP_API_URL}/files/default_no_image.png`;
const DEFAULT_VIDEO_URL = `${process.env.REACT_APP_API_URL}/files/default_no_video.png`;
const DEFAULT_AVATAR_URL = `${process.env.REACT_APP_API_URL}/files/defaultUser.png`;

/**
 * Hàm hỗ trợ an toàn: Tự động chèn /files/ và dọn dẹp dấu / thừa
 */
const formatMediaRoute = (path: string): string => {
  // Cắt bỏ dấu '/' ở đầu nếu có (tránh lỗi /files//avatar.jpg)
  const cleanPath = path.startsWith('/') ? path.substring(1) : path;

  // Nếu path đã có chữ files/ rồi thì thôi, nếu chưa có thì thêm vào
  if (cleanPath.startsWith('files/')) {
    return cleanPath;
  }
  return `files/${cleanPath}`;
};

/**
 * Get image URL with fallback to default image
 * @param imagePath - The image path from API
 * @returns Full image URL with fallback
 */
export const getImageUrl = (imagePath?: string): string => {
  if (!imagePath) {
    return DEFAULT_IMAGE_URL;
  }

  if (imagePath.startsWith("http")) {
    return imagePath;
  }

  // Đã áp dụng hàm formatMediaRoute
  return `${process.env.REACT_APP_API_URL}/${formatMediaRoute(imagePath)}`;
};

/**
 * Get avatar URL with fallback to default image (consistent with other pages)
 * @param avatar - The avatar path from API
 * @returns Full avatar URL with fallback
 */
export const getAvatarUrl = (avatar?: string): string => {
  if (!avatar || avatar === "defaultUser.png") {
    return DEFAULT_AVATAR_URL;
  }
  if (avatar.startsWith("http")) {
    return avatar;
  }

  // Đã áp dụng hàm formatMediaRoute
  return `${process.env.REACT_APP_API_URL}/${formatMediaRoute(avatar)}`;
};

/**
 * Get video URL with fallback to default video (consistent with other pages)
 * @param videoPath - The video path from API
 * @returns Full video URL with fallback
 */
export const getVideoUrl = (videoPath?: string): string => {
  if (!videoPath) {
    return DEFAULT_VIDEO_URL;
  }
  if (videoPath.startsWith("http")) {
    return videoPath;
  }

  // Đã áp dụng hàm formatMediaRoute
  return `${process.env.REACT_APP_API_URL}/${formatMediaRoute(videoPath)}`;
}

/**
 * Handle image load error by setting fallback image
 * @param event - The error event
 */
export const handleImageError = (event: React.SyntheticEvent<HTMLImageElement>) => {
  const target = event.target as HTMLImageElement;
  if (target.src !== DEFAULT_IMAGE_URL) {
    target.src = DEFAULT_IMAGE_URL;
  }
};

/**
 * Handle video load error by replacing with fallback image
 * @param event - The error event
 */
export const handleVideoError = (event: React.SyntheticEvent<HTMLVideoElement>) => {
  const target = event.target as HTMLVideoElement;
  const img = document.createElement("img");
  img.src = DEFAULT_VIDEO_URL;
  img.style.width = target.style.width || "120px";
  img.style.height = target.style.height || "80px";
  img.style.objectFit = "cover";
  img.style.borderRadius = target.style.borderRadius || "8px";
  img.style.border = target.style.border || "1px solid #ddd";
  img.alt = "Video không khả dụng";

  if (target.parentNode) {
    target.parentNode.replaceChild(img, target);
  }
};

const imageUtils = {
  getImageUrl,
  getAvatarUrl,
  handleImageError,
  handleVideoError,
  getVideoUrl,
  DEFAULT_IMAGE_URL,
};

export default imageUtils;