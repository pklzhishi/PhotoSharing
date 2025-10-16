import { JsonValue } from './User';

/**
 * 通用空请求体
 */
export interface EmptyRequest {}

/**
 * 点赞/取消点赞请求体
 */
export interface ToggleLikeRequest {
  imageId: number;
}

/** 图片上传表单（匹配 uploadFile 的 formData） */
export interface ImageUploadFormData {
  imageName: string;
}

/** Base64 图片上传请求体（方案B） */
export class ImageUploadBase64Body {
  imageName: string;
  base64: string;

  constructor(imageName: string, base64: string) {
    this.imageName = imageName;
    this.base64 = base64;
  }
}

/** 普通对象格式的 Base64 上传请求体 */
export class ImageUploadObjectBody {
  imageName: string;
  base64: string;

  constructor(imageName: string, base64: string) {
    this.imageName = imageName;
    this.base64 = base64;
  }
}

/** MultipartFile 格式的 Base64 上传请求体 */
export class ImageUploadMultipartBody {
  multipartFile: string;
  imageName: string;

  constructor(multipartFile: string, imageName: string) {
    this.multipartFile = multipartFile;
    this.imageName = imageName;
  }
}

/** 注册请求（匹配后端 /api/user/register） */
export class RegisterRequestData {
  userAccount: JsonValue; // 后端要求的账号字段
  password: JsonValue;    // 后端要求的密码字段
  username: JsonValue;    // 后端要求的用户名字段
  telephoneNumber: JsonValue; // 后端要求的手机号字段

  constructor(userAccount: JsonValue, password: JsonValue, username: JsonValue, telephoneNumber: JsonValue) {
    this.userAccount = userAccount;
    this.password = password;
    this.username = username;
    this.telephoneNumber = telephoneNumber;
  }
}

/** 登录请求（匹配后端 /api/user/login） */
export class LoginRequestData {
  userAccount: JsonValue; // 后端要求的账号字段（非 username）
  password: JsonValue;    // 后端要求的密码字段

  constructor(userAccount: JsonValue, password: JsonValue) {
    this.userAccount = userAccount;
    this.password = password;
  }
}

/** 分页请求（匹配后端 /api/image/getMyImage） */
export class PageRequestData {
  page: JsonValue; // 后端要求的页码字段
  size: JsonValue; // 后端要求的每页条数字段

  constructor(page: JsonValue, size: JsonValue) {
    this.page = page;
    this.size = size;
  }
}

/** 点赞请求（匹配后端 /api/userLike/changeUserLike） */
export class ToggleLikeRequestData {
  imageId: JsonValue; // 后端要求的图片ID字段

  constructor(imageId: JsonValue) {
    this.imageId = imageId;
  }
}

/** 发表评论请求（匹配后端 /api/comments/postComments） */
export class PostCommentRequestData {
  content: JsonValue; // 后端要求的评论内容字段
  imageId: JsonValue; // 后端要求的图片ID字段

  constructor(content: JsonValue, imageId: JsonValue) {
    this.content = content;
    this.imageId = imageId;
  }
}

/** 删除评论请求（匹配后端 /api/comments/deleteComments） */
export class DeleteCommentRequestData {
  id: number; // 后端要求的评论ID字段，根据OpenAPI规范使用id字段

  constructor(id: number) {
    this.id = id;
    console.log('DeleteCommentRequestData构造函数调用');
    console.log('传入的ID:', id);
    console.log('ID类型:', typeof id);
    console.log('设置的id字段:', this.id);
  }
}

/** 空请求（用于无Body的POST接口，如 /api/image/getImageRandomly） */
export class EmptyRequestData {}

/** 搜索图片请求（匹配后端 /api/image/searchImage） */
export class SearchImageRequestData {
  imageName: string;

  constructor(imageName: string) {
    this.imageName = imageName;
  }
}

/** 获取图片信息请求（匹配后端 /api/image/getImageInformation） */
export class GetImageInformationRequestData {
  imageId: number;

  constructor(imageId: number) {
    this.imageId = imageId;
  }
}

/** 收藏/取消收藏请求（匹配后端 /api/bookmark/changeBookmark） */
export class ChangeBookmarkRequestData {
  imageId: number;

  constructor(imageId: number) {
    this.imageId = imageId;
  }
}

/** 获取评论列表请求（匹配后端 /api/comments/getCommentsList） */
export class GetCommentsListRequestData {
  imageId: number;

  constructor(imageId: number) {
    this.imageId = imageId;
  }
}