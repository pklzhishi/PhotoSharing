import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import fs from '@ohos.file.fs';
import image from '@ohos.multimedia.image';
import http from '@ohos.net.http';
import { ImageItem } from '../models/Image';
import { Comment } from '../models/Comment';
import { ApiService } from '../services/ApiService';
import { Colors } from '../common/Colors';
import { BottomNavBar } from '../common/BottomNavBar';

// 定义点赞数据接口
interface LikeData {
  isLiked: boolean;
  likeCount: number;
  timestamp: number;
}

// 定义点赞状态返回接口
interface LikeStatus {
  isLiked: boolean;
  likeCount: number;
}

// 定义收藏数据接口
interface BookmarkData {
  isBookmarked: boolean;
  bookmarkCount: number;
  timestamp: number;
}

// 定义收藏状态返回接口
interface BookmarkStatus {
  isBookmarked: boolean;
  bookmarkCount: number;
}

/**
 * 图片详情页面
 */
@Entry
@Component
struct ImageDetailPage {
  @State imageDetail: ImageItem | null = null;
  @State comments: Comment[] = [];
  @State isLoading: boolean = true;
  @State isLiking: boolean = false;
  @State isCommenting: boolean = false;
  @State newComment: string = '';
  @State imageId: number = 0;
  @State showCommentInput: boolean = false; // 控制评论输入框显示
  @State isBookmarking: boolean = false; // 控制收藏操作状态

  // 使用全局存储评论数据、点赞状态和收藏状态（更持久）
  private static getGlobalStorage(): Record<string, string> {
    // 定义全局存储接口
    interface GlobalStorage {
      commentsStorage?: Record<string, string>;
      likesStorage?: Record<string, string>;
      bookmarksStorage?: Record<string, string>;
    }
    
    const globalStorage = globalThis as GlobalStorage;
    if (!globalStorage.commentsStorage) {
      globalStorage.commentsStorage = {};
    }
    if (!globalStorage.likesStorage) {
      globalStorage.likesStorage = {};
    }
    if (!globalStorage.bookmarksStorage) {
      globalStorage.bookmarksStorage = {};
    }
    return globalStorage.commentsStorage;
  }
  
  // 获取点赞存储
  private static getLikesStorage(): Record<string, string> {
    interface GlobalStorage {
      likesStorage?: Record<string, string>;
    }
    
    const globalStorage = globalThis as GlobalStorage;
    if (!globalStorage.likesStorage) {
      globalStorage.likesStorage = {};
    }
    return globalStorage.likesStorage;
  }

  // 获取收藏存储
  private static getBookmarksStorage(): Record<string, string> {
    interface GlobalStorage {
      bookmarksStorage?: Record<string, string>;
    }
    
    const globalStorage = globalThis as GlobalStorage;
    if (!globalStorage.bookmarksStorage) {
      globalStorage.bookmarksStorage = {};
    }
    return globalStorage.bookmarksStorage;
  }

  aboutToAppear() {
    // 获取传递的参数
    console.log('ImageDetailPage aboutToAppear 被调用');
    interface RouterParams {
      imageId: number;
      imageData?: string; // 可选的图片数据
    }
    const params = router.getParams() as RouterParams;
    console.log('接收到的参数:', params);
    
    if (params && params.imageId) {
      this.imageId = params.imageId;
      console.log('开始加载图片详情，图片ID:', this.imageId);
      
      // 如果传递了完整的图片数据，直接使用
      if (params.imageData) {
        try {
          this.imageDetail = JSON.parse(params.imageData);
          console.log('使用传递的图片数据:', this.imageDetail);
          this.isLoading = false;
          // 仍然尝试加载评论（如果API存在的话）
          this.loadComments();
        } catch (error) {
          console.error('解析图片数据失败:', error);
          this.loadImageDetail();
        }
      } else {
        // 如果没有传递图片数据，尝试从API加载
        this.loadImageDetail();
      }
      
      // 调试：显示当前存储状态
      const storage = ImageDetailPage.getGlobalStorage();
      const likesStorage = ImageDetailPage.getLikesStorage();
      const bookmarksStorage = ImageDetailPage.getBookmarksStorage();
      console.log('页面加载时的存储状态:', Object.keys(storage));
      console.log('页面加载时的点赞存储状态:', Object.keys(likesStorage));
      console.log('页面加载时的收藏存储状态:', Object.keys(bookmarksStorage));
      console.log('当前图片ID的存储key:', `comments_${this.imageId}`);
      console.log('当前图片ID的点赞key:', `like_${this.imageId}`);
      console.log('当前图片ID的收藏key:', `bookmark_${this.imageId}`);
      console.log('是否有当前图片的评论数据:', !!storage[`comments_${this.imageId}`]);
      console.log('是否有当前图片的点赞数据:', !!likesStorage[`like_${this.imageId}`]);
      console.log('是否有当前图片的收藏数据:', !!bookmarksStorage[`bookmark_${this.imageId}`]);
    } else {
      console.error('未接收到有效的图片ID参数');
    }
  }

  /**
   * 加载图片详情
   */
  async loadImageDetail() {
    this.isLoading = true;
    try {
      console.log('开始加载图片详情，图片ID:', this.imageId);
      
      // 由于后端可能没有getImageDetail API，我们使用传递过来的图片数据
      if (this.imageDetail) {
        console.log('使用传递的图片数据:', this.imageDetail);
        
        // 尝试从本地存储加载点赞状态
        const likeStatus = await this.loadLikeStatusFromLocal(this.imageId);
        if (likeStatus) {
          console.log('从本地存储恢复点赞状态:', likeStatus);
          this.imageDetail.isLiked = likeStatus.isLiked;
          this.imageDetail.likeCount = likeStatus.likeCount;
        } else {
          console.log('没有找到本地点赞状态，使用默认值');
        }

        // 尝试从本地存储加载收藏状态
        const bookmarkStatus = await this.loadBookmarkStatusFromLocal(this.imageId);
        if (bookmarkStatus) {
          console.log('从本地存储恢复收藏状态:', bookmarkStatus);
          this.imageDetail.isBookmarked = bookmarkStatus.isBookmarked;
          this.imageDetail.bookmarkCount = bookmarkStatus.bookmarkCount;
        } else {
          console.log('没有找到本地收藏状态，使用默认值');
          this.imageDetail.isBookmarked = false;
          this.imageDetail.bookmarkCount = 0;
        }
      } else {
        console.error('没有图片数据，无法显示详情');
        promptAction.showToast({ message: '图片数据缺失' });
        return;
      }
      
      // 加载评论
      await this.loadComments();
      
    } catch (error) {
      console.error('加载图片详情失败:', error);
      console.error('错误类型:', typeof error);
      console.error('错误详情:', JSON.stringify(error));
      promptAction.showToast({ message: '加载失败' });
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 点赞/取消点赞
   */
  async toggleLike() {
    if (!this.imageDetail || this.isLiking) return;

    this.isLiking = true;
    try {
      // 先更新本地状态
      const oldIsLiked = this.imageDetail.isLiked;
      const oldLikeCount = this.imageDetail.likeCount || 0;
      
      this.imageDetail.isLiked = !this.imageDetail.isLiked;
      this.imageDetail.likeCount = oldLikeCount + (this.imageDetail.isLiked ? 1 : -1);
      
      // 保存到本地存储
      await this.saveLikeStatusToLocal(this.imageDetail.imageId, this.imageDetail.isLiked, this.imageDetail.likeCount);
      
      promptAction.showToast({ 
        message: this.imageDetail.isLiked ? '点赞成功' : '取消点赞' 
      });
      
      // 尝试调用API（即使失败也不影响本地显示）
      try {
        const response = await ApiService.toggleLike(this.imageDetail.imageId);
        console.log('点赞API响应:', response);
        if (response.code === 1) {
          console.log('点赞API调用成功');
        } else {
          console.error('点赞API失败，响应码:', response.code, '错误信息:', response.msg);
        }
      } catch (apiError) {
        console.error('点赞API调用异常:', apiError);
        // API失败不影响本地显示
      }
      
    } catch (error) {
      console.error('点赞失败:', error);
      promptAction.showToast({ message: '操作失败' });
    } finally {
      this.isLiking = false;
    }
  }

  /**
   * 收藏/取消收藏
   */
  async toggleBookmark() {
    if (!this.imageDetail || this.isBookmarking) return;

    this.isBookmarking = true;
    try {
      // 先更新本地状态
      const oldIsBookmarked: boolean = this.imageDetail.isBookmarked || false;
      const oldBookmarkCount: number = this.imageDetail.bookmarkCount || 0;
      
      this.imageDetail.isBookmarked = !oldIsBookmarked;
      this.imageDetail.bookmarkCount = oldBookmarkCount + (this.imageDetail.isBookmarked ? 1 : -1);
      
      // 保存到本地存储
      await this.saveBookmarkStatusToLocal(this.imageDetail.imageId, this.imageDetail.isBookmarked, this.imageDetail.bookmarkCount);
      
      promptAction.showToast({ 
        message: this.imageDetail.isBookmarked ? '收藏成功' : '取消收藏' 
      });
      
      // 尝试调用API（即使失败也不影响本地显示）
      try {
        const response = await ApiService.changeBookmark(this.imageDetail.imageId);
        console.log('收藏API响应:', response);
        if (response.code === 1) {
          console.log('收藏API调用成功');
        } else {
          console.error('收藏API失败，响应码:', response.code, '错误信息:', response.msg);
        }
      } catch (apiError) {
        console.error('收藏API调用异常:', apiError);
        // API失败不影响本地显示
      }
      
    } catch (error) {
      console.error('收藏失败:', error);
      promptAction.showToast({ message: '操作失败' });
    } finally {
      this.isBookmarking = false;
    }
  }

  /**
   * 切换评论输入框显示状态
   */
  toggleCommentInput() {
    this.showCommentInput = !this.showCommentInput;
    if (!this.showCommentInput) {
      // 如果隐藏输入框，清空输入内容
      this.newComment = '';
    }
  }

  /**
   * 发表评论
   */
  async postComment() {
    if (!this.newComment.trim() || this.isCommenting) return;

    this.isCommenting = true;
    try {
      console.log('=== 开始发表评论 ===');
      console.log('评论内容:', this.newComment.trim());
      console.log('图片ID:', this.imageId);
      console.log('图片ID类型:', typeof this.imageId);
      
      // 检查是否有token，如果没有则提示用户登录
      const HttpServiceModule = await import('../services/HttpService');
      const HttpService = HttpServiceModule.HttpService;
      const token = await HttpService.getToken();
      console.log('当前token状态:', token ? '已登录' : '未登录');
      
      if (!token) {
        promptAction.showDialog({
          title: '需要登录',
          message: '发表评论需要先登录，是否前往登录页面？',
          buttons: [
            {
              text: '取消',
              color: '#666666'
            },
            {
              text: '去登录',
              color: '#4CAF50'
            }
          ]
        }).then((result) => {
          if (result.index === 1) {
            // 用户选择去登录
            router.pushUrl({ url: 'pages/LoginPage' });
          }
        });
        this.isCommenting = false;
        return;
      }
      
      // 先保存评论内容，避免在API调用后丢失
      const commentContent = this.newComment.trim();
      
      // 创建新的评论对象
      const newComment: Comment = {
        commentId: Date.now(), // 使用时间戳作为临时ID
        content: commentContent,
        imageId: this.imageId,
        userId: 1, // 假设当前用户ID为1，实际应该从登录状态获取
        username: '我', // 当前用户名
        createTime: new Date().toISOString()
      };
      
      // 先添加到本地列表
      this.comments.unshift(newComment);
      
      // 保存到本地存储
      await this.saveCommentsToLocal(this.comments);
      
      console.log('评论已添加到本地列表，当前评论数量:', this.comments.length);
      
      // 清空输入框和隐藏输入区域
      this.newComment = '';
      this.showCommentInput = false;
      
      // 尝试调用API（即使失败也不影响本地显示）
      try {
        const response = await ApiService.postComment({
          content: commentContent,
          imageId: this.imageId
        });

        console.log('发表评论API响应:', response);
        console.log('响应码:', response.code);
        console.log('响应消息:', response.msg);
        console.log('响应数据:', response.data);

        if (response.code === 1) {
          promptAction.showToast({ message: '评论成功' });
        } else {
          console.error('发表评论API失败，响应码:', response.code, '错误信息:', response.msg);
          promptAction.showToast({ message: '评论已保存到本地，但服务器同步失败' });
        }
      } catch (apiError) {
        console.error('发表评论API调用异常:', apiError);
        promptAction.showToast({ message: '评论已保存到本地，但服务器同步失败' });
      }
    } catch (error) {
      console.error('发表评论失败:', error);
      console.error('错误类型:', typeof error);
      console.error('错误详情:', JSON.stringify(error));
      promptAction.showToast({ message: '评论失败，请检查网络连接' });
    } finally {
      this.isCommenting = false;
    }
  }

  /**
   * 删除评论
   */
  async deleteComment(comment: Comment) {
    if (!comment.commentId) {
      promptAction.showToast({ message: '评论ID无效' });
      return;
    }

    // 检查是否有token，如果没有则提示用户登录
    const HttpServiceModule = await import('../services/HttpService');
    const HttpService = HttpServiceModule.HttpService;
    const token = await HttpService.getToken();
    console.log('删除评论 - 当前token状态:', token ? '已登录' : '未登录');
    
    if (!token) {
      promptAction.showDialog({
        title: '需要登录',
        message: '删除评论需要先登录，是否前往登录页面？',
        buttons: [
          {
            text: '取消',
            color: '#666666'
          },
          {
            text: '去登录',
            color: '#4CAF50'
          }
        ]
      }).then((result) => {
        if (result.index === 1) {
          // 用户选择去登录
          router.pushUrl({ url: 'pages/LoginPage' });
        }
      });
      return;
    }

    // 添加简单的确认提示
    promptAction.showToast({ 
      message: '正在删除评论...',
      duration: 1000
    });

    try {
      console.log('删除评论，评论ID:', comment.commentId, '图片ID:', this.imageId);
      
      const response = await ApiService.deleteComment(comment.commentId, this.imageId);
      
      console.log('删除评论API响应:', response);
      
      if (response.code === 1) {
        promptAction.showToast({ message: '删除成功' });
        
        // 从本地列表中移除
        const originalLength = this.comments.length;
        this.comments = this.comments.filter(c => c.commentId !== comment.commentId);
        
        // 保存到本地存储
        await this.saveCommentsToLocal(this.comments);
        
        console.log('评论已从本地列表删除，原数量:', originalLength, '现数量:', this.comments.length);
      } else {
        console.error('删除评论失败，响应码:', response.code, '错误信息:', response.msg);
        promptAction.showToast({ message: response.msg || '删除失败' });
      }
    } catch (error) {
      console.error('删除评论失败:', error);
      console.error('错误类型:', typeof error);
      console.error('错误详情:', JSON.stringify(error));
      promptAction.showToast({ message: '删除失败，请检查网络连接' });
    }
  }

  /**
   * 重新加载评论
   */
  async loadComments() {
    try {
      console.log('尝试加载评论，图片ID:', this.imageId);
      
      // 尝试使用API获取评论列表
      try {
        console.log('调用 getImageComments API...');
        const commentsResponse = await ApiService.getImageComments(this.imageId);
        console.log('getImageComments 响应:', commentsResponse);
        
        if (commentsResponse.code === 1) {
          this.comments = commentsResponse.data || [];
          console.log('评论列表加载成功，评论数量:', this.comments.length);
          return;
        } else {
          console.error('获取评论失败，响应码:', commentsResponse.code, '错误信息:', commentsResponse.msg);
        }
      } catch (apiError) {
        console.error('API调用失败，可能后端没有实现getImageComments接口:', apiError);
      }
      
      // 如果API失败，尝试从本地存储加载评论
      console.log('尝试从本地存储加载评论...');
      const localComments = await this.loadCommentsFromLocal();
      this.comments = localComments;
      console.log('从本地存储加载评论，数量:', this.comments.length);
      
    } catch (error) {
      console.error('加载评论失败:', error);
      console.error('使用空评论列表');
      this.comments = [];
    }
  }

  /**
   * 从本地存储加载评论
   */
  async loadCommentsFromLocal(): Promise<Comment[]> {
    try {
      // 使用全局存储评论数据
      const commentsKey = `comments_${this.imageId}`;
      const storage = ImageDetailPage.getGlobalStorage();
      console.log('尝试从本地存储加载评论，key:', commentsKey);
      console.log('当前存储的所有keys:', Object.keys(storage));
      
      const storedComments = storage[commentsKey];
      console.log('存储的评论数据:', storedComments);
      
      if (storedComments) {
        const comments = JSON.parse(storedComments) as Comment[];
        console.log('从本地存储加载评论成功，数量:', comments.length);
        console.log('加载的评论内容:', comments);
        return comments;
      } else {
        console.log('没有找到存储的评论数据');
      }
    } catch (error) {
      console.error('从本地存储加载评论失败:', error);
    }
    return [];
  }

  /**
   * 保存评论到本地存储
   */
  async saveCommentsToLocal(comments: Comment[]): Promise<void> {
    try {
      // 使用全局存储评论数据
      const commentsKey = `comments_${this.imageId}`;
      const storage = ImageDetailPage.getGlobalStorage();
      console.log('保存评论到本地存储，key:', commentsKey);
      console.log('要保存的评论数量:', comments.length);
      console.log('要保存的评论内容:', comments);
      
      storage[commentsKey] = JSON.stringify(comments);
      console.log('评论已保存到本地存储，数量:', comments.length);
      console.log('保存后的存储内容:', storage[commentsKey]);
      console.log('全局存储状态:', Object.keys(storage));
    } catch (error) {
      console.error('保存评论到本地存储失败:', error);
    }
  }

  /**
   * 保存点赞状态到本地存储
   */
  async saveLikeStatusToLocal(imageId: number, isLiked: boolean, likeCount: number): Promise<void> {
    try {
      const likeKey = `like_${imageId}`;
      const likesStorage = ImageDetailPage.getLikesStorage();
      const likeData: LikeData = {
        isLiked: isLiked,
        likeCount: likeCount,
        timestamp: Date.now()
      };
      
      console.log('保存点赞状态到本地存储，key:', likeKey);
      console.log('点赞状态:', likeData);
      
      likesStorage[likeKey] = JSON.stringify(likeData);
      console.log('点赞状态已保存到本地存储');
      console.log('点赞存储状态:', Object.keys(likesStorage));
    } catch (error) {
      console.error('保存点赞状态到本地存储失败:', error);
    }
  }

  /**
   * 从本地存储加载点赞状态
   */
  async loadLikeStatusFromLocal(imageId: number): Promise<LikeStatus | null> {
    try {
      const likeKey = `like_${imageId}`;
      const likesStorage = ImageDetailPage.getLikesStorage();
      console.log('尝试从本地存储加载点赞状态，key:', likeKey);
      console.log('当前点赞存储的所有keys:', Object.keys(likesStorage));
      
      const storedLikeData = likesStorage[likeKey];
      console.log('存储的点赞数据:', storedLikeData);
      
      if (storedLikeData) {
        const likeData = JSON.parse(storedLikeData) as LikeData;
        console.log('从本地存储加载点赞状态成功:', likeData);
        const likeStatus: LikeStatus = {
          isLiked: likeData.isLiked,
          likeCount: likeData.likeCount
        };
        return likeStatus;
      } else {
        console.log('没有找到存储的点赞数据');
      }
    } catch (error) {
      console.error('从本地存储加载点赞状态失败:', error);
    }
    return null;
  }

  /**
   * 保存收藏状态到本地存储
   */
  async saveBookmarkStatusToLocal(imageId: number, isBookmarked: boolean, bookmarkCount: number): Promise<void> {
    try {
      const bookmarkKey = `bookmark_${imageId}`;
      const bookmarksStorage = ImageDetailPage.getBookmarksStorage();
      const bookmarkData: BookmarkData = {
        isBookmarked: isBookmarked,
        bookmarkCount: bookmarkCount,
        timestamp: Date.now()
      };
      
      console.log('保存收藏状态到本地存储，key:', bookmarkKey);
      console.log('收藏状态:', bookmarkData);
      
      bookmarksStorage[bookmarkKey] = JSON.stringify(bookmarkData);
      console.log('收藏状态已保存到本地存储');
      console.log('收藏存储状态:', Object.keys(bookmarksStorage));
    } catch (error) {
      console.error('保存收藏状态到本地存储失败:', error);
    }
  }

  /**
   * 从本地存储加载收藏状态
   */
  async loadBookmarkStatusFromLocal(imageId: number): Promise<BookmarkStatus | null> {
    try {
      const bookmarkKey = `bookmark_${imageId}`;
      const bookmarksStorage = ImageDetailPage.getBookmarksStorage();
      console.log('尝试从本地存储加载收藏状态，key:', bookmarkKey);
      console.log('当前收藏存储的所有keys:', Object.keys(bookmarksStorage));
      
      const storedBookmarkData = bookmarksStorage[bookmarkKey];
      console.log('存储的收藏数据:', storedBookmarkData);
      
      if (storedBookmarkData) {
        const bookmarkData = JSON.parse(storedBookmarkData) as BookmarkData;
        console.log('从本地存储加载收藏状态成功:', bookmarkData);
        const bookmarkStatus: BookmarkStatus = {
          isBookmarked: bookmarkData.isBookmarked,
          bookmarkCount: bookmarkData.bookmarkCount
        };
        return bookmarkStatus;
      } else {
        console.log('没有找到存储的收藏数据');
      }
    } catch (error) {
      console.error('从本地存储加载收藏状态失败:', error);
    }
    return null;
  }

  /**
   * 保存图片到相册
   */
  async saveImage() {
    if (!this.imageDetail) {
      console.error('图片详情为空，无法保存');
      return;
    }

    try {
      console.log('=== 开始保存图片 ===');
      console.log('图片URL:', this.imageDetail.imageUrl);
      
      // 显示保存中提示
      promptAction.showToast({ 
        message: '正在保存图片...',
        duration: 1000
      });

      // 下载图片
      console.log('步骤1: 开始下载图片');
      const imageData = await this.downloadImage(this.imageDetail.imageUrl);
      if (!imageData) {
        console.error('图片下载失败，尝试创建测试文件');
        // 如果下载失败，创建一个简单的测试文件
        const testData = new ArrayBuffer(1024); // 1KB的测试数据
        const testArray = new Uint8Array(testData);
        for (let i = 0; i < testArray.length; i++) {
          testArray[i] = i % 256; // 填充测试数据
        }
        
        const timestamp = new Date().getTime();
        const fileName = `PhotoSharing_${timestamp}.txt`;
        const dirPath = '/data/storage/el2/base/cache';
        const filePath = `${dirPath}/${fileName}`;
        
        try {
          await fs.mkdir(dirPath, true);
          const file = await fs.open(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
          await fs.write(file.fd, testData);
          await fs.close(file.fd);
          
          promptAction.showToast({ 
            message: '测试文件已保存！',
            duration: 3000
          });
          
          console.log('测试文件保存成功:', filePath);
          return;
        } catch (testError) {
          console.error('测试文件保存也失败:', testError);
          throw new Error('下载图片失败且无法创建测试文件');
        }
      }
      console.log('步骤1: 图片下载成功，数据大小:', imageData.byteLength);

      // 创建图片源
      console.log('步骤2: 创建图片源');
      const imageSource = image.createImageSource(imageData);
      
      // 创建PixelMap
      console.log('步骤3: 创建PixelMap');
      const pixelMap = await imageSource.createPixelMap();
      
      // 创建图片打包器
      console.log('步骤4: 创建图片打包器');
      const imagePacker = image.createImagePacker();
      const packOpts: image.PackingOption = {
        format: 'image/jpeg',
        quality: 90
      };
      
      // 打包图片
      console.log('步骤5: 打包图片');
      const arrayBuffer = await imagePacker.packing(pixelMap, packOpts);
      console.log('步骤5: 图片打包成功，大小:', arrayBuffer.byteLength);
      
      // 生成文件名和路径
      const timestamp = new Date().getTime();
      const fileName = `PhotoSharing_${timestamp}.jpg`;
      console.log('步骤6: 生成文件名:', fileName);
      
      // 尝试保存到用户可访问的目录
      let dirPath = '';
      let filePath = '';
      
      try {
        // 首先尝试保存到Documents目录
        dirPath = '/data/storage/el2/base/haps/entry/files/Documents';
        filePath = `${dirPath}/${fileName}`;
        console.log('步骤7: 尝试Documents目录:', filePath);
        await fs.mkdir(dirPath, true);
        console.log('步骤7: Documents目录创建成功');
      } catch (e) {
        try {
          // 如果Documents目录失败，尝试保存到Downloads目录
          dirPath = '/data/storage/el2/base/haps/entry/files/Downloads';
          filePath = `${dirPath}/${fileName}`;
          console.log('步骤7: 尝试Downloads目录:', filePath);
          await fs.mkdir(dirPath, true);
          console.log('步骤7: Downloads目录创建成功');
        } catch (e2) {
          // 最后使用cache目录作为备用
          dirPath = '/data/storage/el2/base/cache';
          filePath = `${dirPath}/${fileName}`;
          console.log('步骤7: 使用缓存目录:', filePath);
          await fs.mkdir(dirPath, true);
          console.log('步骤7: 缓存目录创建成功');
        }
      }
      
      // 写入文件
      console.log('步骤9: 开始写入文件');
      const file = await fs.open(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
      console.log('步骤9: 文件打开成功，fd:', file.fd);
      
      await fs.write(file.fd, arrayBuffer);
      console.log('步骤10: 文件写入成功');
      
      await fs.close(file.fd);
      console.log('步骤11: 文件关闭成功');
      
      // 释放资源
      console.log('步骤12: 释放资源');
      imageSource.release();
      pixelMap.release();
      imagePacker.release();
      
      // 显示保存路径信息
      const pathInfo = dirPath.includes('Documents') ? 'Documents目录' : 
                      dirPath.includes('Downloads') ? 'Downloads目录' : '应用缓存目录';
      
      promptAction.showToast({ 
        message: `图片已保存到${pathInfo}！`,
        duration: 3000
      });
      
      console.log('=== 图片保存完成 ===');
      console.log('保存路径:', filePath);
      console.log('保存目录:', dirPath);
      console.log('文件大小:', arrayBuffer.byteLength, 'bytes');
      
    } catch (error) {
      console.error('=== 保存图片失败 ===');
      console.error('错误类型:', typeof error);
      console.error('错误信息:', error);
      console.error('错误堆栈:', (error as Error).stack);
      
      promptAction.showToast({ 
        message: '保存失败: ' + (error as Error).message,
        duration: 2000
      });
    }
  }

  /**
   * 下载图片数据
   */
  private async downloadImage(url: string): Promise<ArrayBuffer | null> {
    try {
      console.log('=== 开始下载图片 ===');
      console.log('图片URL:', url);
      
      const httpRequest = http.createHttp();
      console.log('HTTP请求对象创建成功');
      
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json'
        }
      });
      
      console.log('HTTP响应状态码:', response.responseCode);
      console.log('响应头:', response.header);
      
      if (response.responseCode === 200) {
        const result = response.result as ArrayBuffer;
        console.log('图片下载成功，数据大小:', result.byteLength);
        return result;
      } else {
        console.error('图片下载失败，状态码:', response.responseCode);
        console.error('响应消息:', response.header);
        return null;
      }
    } catch (error) {
      console.error('=== 下载图片异常 ===');
      console.error('错误类型:', typeof error);
      console.error('错误信息:', error);
      console.error('错误堆栈:', (error as Error).stack);
      return null;
    }
  }


  /**
   * 格式化时间显示
   */
  formatTime(timeString?: string): string {
    if (!timeString) return '';
    
    try {
      const date = new Date(timeString);
      const now = new Date();
      const diff = now.getTime() - date.getTime();
      
      // 小于1分钟
      if (diff < 60000) {
        return '刚刚';
      }
      // 小于1小时
      else if (diff < 3600000) {
        return `${Math.floor(diff / 60000)}分钟前`;
      }
      // 小于1天
      else if (diff < 86400000) {
        return `${Math.floor(diff / 3600000)}小时前`;
      }
      // 小于7天
      else if (diff < 604800000) {
        return `${Math.floor(diff / 86400000)}天前`;
      }
      // 超过7天，显示具体日期
      else {
        return date.toLocaleDateString('zh-CN', {
          month: 'short',
          day: 'numeric',
          hour: '2-digit',
          minute: '2-digit'
        });
      }
    } catch (error) {
      console.error('时间格式化失败:', error);
      return timeString;
    }
  }

  /**
   * 返回
   */
  goBack() {
    router.back();
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor(Color.Black)
          .onClick(() => this.goBack())

        Text('图片详情')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Black)
          .margin({ left: 16 })

        Blank()

        // 保存按钮
        Text('💾')
          .fontSize(20)
          .fontColor(Color.Black)
          .onClick(() => this.saveImage())
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.Transparent)

      if (this.isLoading) {
        // 加载中状态
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
            .color('#4CAF50')
          
          Text('加载中...')
            .fontSize(16)
            .fontColor(Color.Black)
            .margin({ top: 16 })
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .height('100%')
      } else if (this.imageDetail) {
        // 图片详情内容
        Scroll() {
          Column({ space: 16 }) {
            // 图片
            Image(this.imageDetail.imageUrl)
              .width('100%')
              .height(300)
              .borderRadius(12)
              .objectFit(ImageFit.Cover)
              .backgroundColor(Colors.White20)
              .gesture(
                TapGesture({ count: 2 })
                  .onAction(() => {
                    console.log('双击图片，开始保存');
                    this.saveImage();
                  })
              )

            // 图片信息
            Column({ space: 12 }) {
              // 图片名称
              Text(this.imageDetail.imageName)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.Black)
                .width('100%')
                .textAlign(TextAlign.Start)

              // 作者信息
              Row() {
                Text(`by ${this.imageDetail.username || '匿名用户'}`)
                  .fontSize(14)
                  .fontColor(Colors.Black60)

                Blank()

                Text(this.imageDetail.uploadTime || '')
                  .fontSize(12)
                  .fontColor(Colors.Black40)
              }
              .width('100%')

              // 图片描述
              if (this.imageDetail.content) {
                Text(this.imageDetail.content)
                  .fontSize(14)
                  .fontColor(Color.Black)
                  .width('100%')
                  .textAlign(TextAlign.Start)
                  .lineHeight(20)
              }

              // 互动区域
              Row({ space: 20 }) {
                // 点赞按钮
                Row({ space: 8 }) {
                  Text(this.imageDetail.isLiked ? '❤️' : '🤍')
                    .fontSize(20)
                    .onClick(() => this.toggleLike())

                  Text((this.imageDetail.likeCount || 0).toString())
                    .fontSize(14)
                    .fontColor(Colors.Black60)
                }

                // 收藏按钮
                Row({ space: 8 }) {
                  Text(this.imageDetail.isBookmarked ? '⭐' : '☆')
                    .fontSize(20)
                    .onClick(() => this.toggleBookmark())

                  Text((this.imageDetail.bookmarkCount || 0).toString())
                    .fontSize(14)
                    .fontColor(Colors.Black60)
                }

                // 评论数
                Row({ space: 8 }) {
                  Text('💬')
                    .fontSize(20)

                  Text((this.comments.length).toString())
                    .fontSize(14)
                    .fontColor(Colors.Black60)
                }
              }
              .width('100%')
              .justifyContent(FlexAlign.Start)
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(12)

            // 评论区域
            Column({ space: 12 }) {
              Text('评论')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(Color.Black)
                .alignSelf(ItemAlign.Start)

              // 评论列表
              if (this.comments.length > 0) {
                Column({ space: 12 }) {
                  ForEach(this.comments, (comment: Comment, index: number) => {
                    Column({ space: 8 }) {
                      Row() {
                        Text(comment.username || '匿名用户')
                          .fontSize(12)
                          .fontColor(Colors.Black60)

                        Blank()

                        Text(this.formatTime(comment.createTime))
                          .fontSize(12)
                          .fontColor(Colors.Black40)
                      }
                      .width('100%')

                      Text(comment.content)
                        .fontSize(14)
                        .fontColor(Color.Black)
                        .width('100%')
                        .textAlign(TextAlign.Start)
                        .lineHeight(18)

                      // 删除按钮（仅显示自己的评论）
                      if (comment.userId === 1) { // 假设当前用户ID为1
                        Row() {
                          Blank()
                          Text('删除')
                            .fontSize(12)
                            .fontColor('#FF5722')
                            .padding({ top: 4, bottom: 4, left: 8, right: 8 })
                            .backgroundColor('#FFF5F5')
                            .borderRadius(4)
                            .onClick(() => {
                              // 直接删除
                              this.deleteComment(comment);
                            })
                        }
                        .width('100%')
                        .justifyContent(FlexAlign.End)
                        .margin({ top: 4 })
                      }
                    }
                    .width('100%')
                    .padding(12)
                    .backgroundColor(Colors.White10)
                    .borderRadius(8)
                    .alignItems(HorizontalAlign.Start)
                  })
                }
              } else {
                Text('暂无评论')
                  .fontSize(14)
                  .fontColor(Colors.Black40)
                  .textAlign(TextAlign.Center)
                  .width('100%')
                  .padding(20)
              }

              // 发表评论区域
              Column({ space: 8 }) {
                if (!this.showCommentInput) {
                  // 显示"发表评论"按钮
                  Button('发表评论')
                    .width('100%')
                    .height(40)
                    .backgroundColor('#4CAF50')
                    .fontColor(Color.White)
                    .borderRadius(8)
                    .onClick(() => this.toggleCommentInput())
                } else {
                  // 显示输入框和发送按钮
                  Column({ space: 8 }) {
                    TextArea({ placeholder: '写下你的评论...' })
                      .width('100%')
                      .height(80)
                      .backgroundColor(Color.White)
                      .borderRadius(8)
                      .fontSize(14)
                      .fontColor(Color.Black)
                      .placeholderColor(Colors.Black40)
                      .onChange((value: string) => {
                        this.newComment = value;
                      })

                    Button(this.isCommenting ? '发送中...' : '发送')
                      .width('100%')
                      .height(40)
                      .backgroundColor('#4CAF50')
                      .fontColor(Color.White)
                      .borderRadius(8)
                      .enabled(!this.isCommenting && this.newComment.trim() !== '')
                      .onClick(() => this.postComment())
                    .width('100%')
                  }
                }
              }
              .width('100%')
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(12)
          }
          .width('100%')
          .padding(16)
        }
        .layoutWeight(1)
      } else {
        // 错误状态
        Column() {
          Text('😞')
            .fontSize(48)
            .margin({ bottom: 16 })

          Text('加载失败')
            .fontSize(16)
            .fontColor(Color.Black)
            .margin({ bottom: 8 })

          Button('重试')
            .width(100)
            .height(40)
            .backgroundColor('#4CAF50')
            .fontColor(Color.White)
            .borderRadius(8)
            .onClick(() => this.loadImageDetail())
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .height('100%')
      }

      // 底部导航栏
      BottomNavBar({ currentPage: 'home' })
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [
        ['#E8F5E8', 0.0],
        ['#F0F8F0', 0.3],
        ['#F8FCF8', 0.7],
        ['#FFFFFF', 1.0]
      ]
    })
  }
}
