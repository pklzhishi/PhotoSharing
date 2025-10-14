import { HttpService } from './HttpService';
import { LoginRequest, RegisterRequest, ApiResponse, LoginSuccessData } from '../models/User';
import { ImageItem, ImageUploadRequest, PageRequest, PageResponse } from '../models/Image';
import { PostCommentRequest } from '../models/Comment';
import { RegisterRequestData, LoginRequestData, PageRequestData, ToggleLikeRequestData, PostCommentRequestData, DeleteCommentRequestData, EmptyRequestData, ImageUploadBase64Body, ImageUploadObjectBody, ImageUploadMultipartBody, SearchImageRequestData } from '../models/ApiRequest';

/** API服务类（完全适配后端接口） */
export class ApiService {
 // private URLSearchParams;
  /** 用户注册（适配后端 /api/user/register） */
  static async register(data: RegisterRequest): Promise<ApiResponse<void>> {
    const requestData = new RegisterRequestData(
      data.userAccount,
      data.password,
      data.username,
      data.telephoneNumber
    );
    return HttpService.post<void, RegisterRequestData>('/api/user/register', requestData);
  }

  /** 用户登录（适配后端 /api/user/login） */
  static async login(data: LoginRequest): Promise<ApiResponse<LoginSuccessData>> {
    const requestData = new LoginRequestData(
      data.userAccount,
      data.password
    );
    return HttpService.post<LoginSuccessData, LoginRequestData>('/api/user/login', requestData);
  }

  /** 上传图片（Base64 方案，使用原接口 /api/image/imageUpload） */
  // static async uploadImage(data: ImageUploadRequest): Promise<ApiResponse<void>> {
  //   // 这里由调用方先把文件读成 base64 再传入，此方法保持签名不变
  //   // 为兼容调用方现有传参，此处只负责将已读取的 base64 发给后端
  //   // 注意：真正的 base64 字符串由 UploadPage 读取后通过 data.imageName + base64 传递过来
  //   throw new Error('uploadImage should be called via ApiService.uploadImageBase64 in Base64 mode');
  // }
  //
  // /** 新增：显式的 Base64 上传方法（使用原接口） */
  // static async uploadImageBase64(imageName: string, base64: string): Promise<ApiResponse<void>> {
  //   // 根据后端接口文档，使用 multipartFile 字段名
  //   console.log('使用 multipartFile 格式上传');
  //   const body = new ImageUploadMultipartBody(base64, imageName);
  //   return HttpService.post<void, ImageUploadMultipartBody>('/api/image/imageUpload', body);
  // }

  /** 真正的文件上传方法（使用文件路径） */
  static async uploadImageFile(imageName: string, filePath: string, content: string = '', userImageName?: string): Promise<ApiResponse<void>> {
    console.log('使用文件路径上传:', filePath);
    return HttpService.uploadFile<void>('/api/image/imageUpload', filePath, imageName, content, undefined, userImageName);
  }

  /** MultipartBuilder文件上传方法（使用自定义MultipartBuilder） */
  static async uploadImageFileWithBuilder(imageName: string, filePath: string, content: string = '', userImageName?: string): Promise<ApiResponse<void>> {
    console.log('使用MultipartBuilder上传文件:', filePath);
    return HttpService.uploadFileWithBuilder<void>('/api/image/imageUpload', filePath, imageName, content, undefined, userImageName);
  }

  /** 原生FormData文件上传方法（使用鸿蒙原生FormData） */
  static async uploadImageFileFormData(imageName: string, filePath: string, content: string = ''): Promise<ApiResponse<void>> {
    console.log('使用鸿蒙原生FormData上传文件:', filePath);
    return HttpService.uploadFileNative<void>('/api/image/imageUpload', filePath, imageName, content);
  }
  //
  // /** 使用官方推荐的文件上传方法 */
  // static async uploadImageFileOfficial(imageName: string, filePath: string, content: string = ''): Promise<ApiResponse<void>> {
  //   console.log('使用官方postFile方法上传文件:', filePath);
  //   return HttpService.uploadFileOfficial<void>('/api/image/imageUpload', filePath, imageName, content);
  // }
  //
  // /** 使用@ohos.request.uploadFile进行文件上传（最推荐的方法） */
  // static async uploadImageFileWithRequest(imageName: string, filePath: string, content: string = ''): Promise<ApiResponse<void>> {
  //   console.log('使用@ohos.request.uploadFile上传文件:', filePath);
  //   return HttpService.uploadFileWithRequest<void>('/api/image/imageUpload', filePath, imageName, content);
  // }

  /** 随机获取图片（适配后端 /api/image/getImageRandomly） */
  static async getRandomImages(count: number = 8): Promise<ApiResponse<ImageItem[]>> {
    const url = `/api/image/getImageRandomly?count=${count}`;
    const emptyData = new EmptyRequestData();
    return HttpService.post<ImageItem[], EmptyRequestData>(url, emptyData);
  }

  /** 查看我的发布（适配后端 /api/image/getMyImage） */
  static async getMyImages(pageData: PageRequest): Promise<ApiResponse<PageResponse<ImageItem>>> {
    const requestData = new PageRequestData(pageData.page, pageData.size);
    return HttpService.post<PageResponse<ImageItem>, PageRequestData>('/api/image/getMyImage', requestData);
  }

  /** 获取个人发布作品数（适配后端 /api/image/getMyImageNumber） */
  static async getMyImageCount(): Promise<ApiResponse<number>> {
    return HttpService.get<number>('/api/image/getMyImageNumber');
  }

  /** 点赞/取消点赞（适配后端 /api/userLike/changeUserLike） */
  static async toggleLike(imageId: number): Promise<ApiResponse<void>> {
    const requestData = new ToggleLikeRequestData(imageId);
    return HttpService.post<void, ToggleLikeRequestData>('/api/userLike/changeUserLike', requestData);
  }

  /** 发表评论（适配后端 /api/comments/postComments） */
  static async postComment(data: PostCommentRequest): Promise<ApiResponse<void>> {
    const requestData = new PostCommentRequestData(data.content, data.imageId);
    return HttpService.post<void, PostCommentRequestData>('/api/comments/postComments', requestData);
  }

  /** 删除评论（适配后端 /api/comments/deleteComments） */
  static async deleteComment(commentId: number, imageId?: number): Promise<ApiResponse<void>> {
    const params = imageId ? `?imageId=${imageId}` : '';
    const requestData = new DeleteCommentRequestData(commentId);
    return HttpService.post<void, DeleteCommentRequestData>(`/api/comments/deleteComments${params}`, requestData);
  }

  /** 搜索图片（适配后端 /api/image/searchImage） */
   // static async searchImage(imageName: string): Promise<ApiResponse<ImageItem[]>> {
   //  const url = `/api/image/searchImage?imageName=${imageName}`;
   //  const emptyData = new EmptyRequestData();
   //  return HttpService.post<ImageItem[], EmptyRequestData>(url, emptyData);
   // }
  static async searchImage(imageName: string): Promise<ApiResponse<ImageItem[]>> {
    const url = `/api/image/searchImage`;
    const searchImage = new SearchImageRequestData(imageName);
    return HttpService.post<ImageItem[], SearchImageRequestData>(url, searchImage);
  }
  /** 随机获取图片（适配后端 /api/image/getImageRandomly） */
  // static async getRandomImages(count: number = 8): Promise<ApiResponse<ImageItem[]>> {
  //   const url = `/api/image/getImageRandomly?count=${count}`;
  //   const emptyData = new EmptyRequestData();
  //   return HttpService.post<ImageItem[], EmptyRequestData>(url, emptyData);
  // }
}
