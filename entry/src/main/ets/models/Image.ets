/**
 * 图片数据模型
 */
export interface ImageItem {
  imageId: number;
  imageName: string;
  imageUrl: string;
  uploadTime?: string;
  userId?: number;
  username?: string;
  likeCount?: number;
  isLiked?: boolean;
}

/**
 * 图片上传请求
 */
export interface ImageUploadRequest {
  imageName: string;
  multipartFile: string; // 文件路径
  content: string; // 内容描述
}

/**
 * 分页请求参数
 */
export interface PageRequest {
  page: number;
  size: number;
}

/**
 * 分页响应数据
 */
export interface PageResponse<T> {
  records: T[];
  total: number;
  size: number;
  current: number;
  pages: number;
}
