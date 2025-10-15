import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { ImageItem, PageRequest, PageResponse } from '../models/Image';
import { ApiService } from '../services/ApiService';
import { HttpService } from '../services/HttpService';
import { Colors } from '../common/Colors';
import { BottomNavBar } from '../common/BottomNavBar';

/** 图片摘要信息接口 */
interface ImageSummary {
  id: number;
  name: string;
}

/** 图片列表项接口 */
interface ImageListItem {
  id: number;
  name: string;
}

/** 图片数量响应数据接口 */
interface ImageCountData {
  number: number;
}

/**
 * 个人中心页面
 */
@Entry
@Component
struct ProfilePage {
  @State myImages: ImageItem[] = [];
  @State imageCount: number = 0;
  @State isLoading: boolean = false;
  @State isRefreshing: boolean = false;
  @State currentPage: number = 1;
  @State hasMore: boolean = true;
  @State isLoggedIn: boolean = false;
  @State currentUsername: string = '我';
  @State currentUserAccount: string = '';
  @State currentTab: string = 'works'; // 'works'、'favorites' 或 'history'
  @State favoriteCount: number = 0;
  @State historyCount: number = 0;

  aboutToAppear() {
    this.loadUserInfo();
    this.loadMyImages(true);
    this.loadFavoriteCount();
    this.loadHistoryCount();
  }

  onPageShow() {
    // 页面显示时重新加载用户信息，确保登录状态更新后能刷新页面
    console.log('ProfilePage onPageShow - 重新加载用户信息');
    this.loadUserInfo();
  }

  /**
   * 加载用户信息
   */
  async loadUserInfo() {
    try {
      // 先检查是否有token
      const token = await HttpService.getToken();
      console.log('检查用户登录状态，token:', token ? '存在' : '不存在');
      
      if (!token) {
        this.isLoggedIn = false;
        this.imageCount = 0;
        this.currentUsername = '我';
        this.currentUserAccount = 'user@example.com';
        return;
      }

      // 有token，尝试获取用户信息
      this.isLoggedIn = true; // 先设置为已登录状态
      
      try {
        // 先获取用户基本信息
        console.log('开始获取用户信息');
        const userInfoResponse = await ApiService.getUserInfo();
        console.log('获取用户信息响应:', JSON.stringify(userInfoResponse, null, 2));
        
        if (userInfoResponse.code === 1 && userInfoResponse.data) {
          // 设置真实用户信息
          this.currentUsername = userInfoResponse.data.username || '我';
          this.currentUserAccount = userInfoResponse.data.userAccount || 'user@example.com';
          console.log('用户信息获取成功:', this.currentUsername, this.currentUserAccount);
        } else {
          // 如果获取用户信息失败，使用默认值
          this.currentUsername = '我';
          this.currentUserAccount = 'user@example.com';
          console.log('使用默认用户信息');
        }
      } catch (userInfoError) {
        console.error('获取用户信息失败:', userInfoError);
        // 即使获取用户信息失败，也保持登录状态
        this.currentUsername = '我';
        this.currentUserAccount = 'user@example.com';
      }

      try {
        // 获取用户图片数量
        console.log('开始获取用户图片数量');
        const response = await ApiService.getMyImageCount();
        console.log('获取图片数量响应:', JSON.stringify(response, null, 2));
        
        if (response.code === 1) {
          // 后端返回的数据结构是 {number: 2}，需要提取number字段
          if (response.data && typeof response.data === 'object') {
            const data = response.data as ImageCountData;
            this.imageCount = data.number || 0;
          } else {
            this.imageCount = 0;
          }
          console.log('用户已登录，图片数量:', this.imageCount);
        } else {
          this.imageCount = 0;
          console.error('获取图片数量失败，响应码:', response.code, '消息:', response.msg);
        }
      } catch (imageCountError) {
        console.error('获取图片数量失败:', imageCountError);
        this.imageCount = 0;
      }
      
    } catch (error) {
      console.error('加载用户信息失败:', error);
      // 只有在没有token的情况下才设置为未登录
      const token = await HttpService.getToken();
      if (!token) {
        this.isLoggedIn = false;
        this.imageCount = 0;
      }
    }
  }

  /**
   * 加载我的图片
   */
  async loadMyImages(refresh: boolean = false) {
    if (refresh) {
      this.currentPage = 1;
      this.myImages = [];
      this.hasMore = true;
    }

    this.isLoading = true;
    try {
      const request: PageRequest = {
        page: this.currentPage,
        size: 8
      };

      console.log('开始加载我的图片，请求参数:', request);
      const response = await ApiService.getMyImages(request);
      console.log('获取我的图片响应:', JSON.stringify(response, null, 2));
      
      if (response.code === 1) {
        // 后端返回的是直接数组，不是分页对象
        if (Array.isArray(response.data)) {
          const imageList = response.data as ImageItem[];
          console.log('图片数据:', JSON.stringify(imageList, null, 2));
          console.log('图片记录数:', imageList?.length || 0);
          
          if (refresh) {
            this.myImages = imageList || [];
          } else {
            this.myImages = [...this.myImages, ...(imageList || [])];
          }
          // 由于后端返回的是简单数组，没有分页信息，所以设置hasMore为false
          this.hasMore = false;
          console.log('最终图片列表长度:', this.myImages.length);
          console.log('图片列表:', this.myImages.map(img => {
            const summary: ImageSummary = {id: img.imageId, name: img.imageName};
            return summary;
          }));
        } else {
          console.error('后端返回的数据不是数组格式:', response.data);
          this.myImages = [];
          this.hasMore = false;
        }
      } else {
        console.error('获取我的图片失败，响应码:', response.code, '消息:', response.msg);
        console.error('完整响应:', JSON.stringify(response, null, 2));
      }
    } catch (error) {
      console.error('加载我的图片失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 刷新数据
   */
  async refreshData() {
    this.isRefreshing = true;
    try {
      await this.loadUserInfo();
      await this.loadMyImages(true);
    } finally {
      this.isRefreshing = false;
    }
  }

  /**
   * 加载更多
   */
  loadMore() {
    if (this.hasMore && !this.isLoading) {
      this.currentPage++;
      this.loadMyImages();
    }
  }

  /**
   * 跳转到登录页�?
   */
  navigateToLogin() {
    router.pushUrl({ url: 'pages/LoginPage' });
  }

  /**
   * 跳转到上传页�?
   */
  navigateToUpload() {
    router.pushUrl({ url: 'pages/UploadPage' });
  }

  /**
   * 返回
   */
  goBack() {
    router.back();
  }

  /**
   * 点赞/取消点赞
   */
  async toggleLike(image: ImageItem) {
    try {
      const response = await ApiService.toggleLike(image.imageId);
      if (response.code === 1) {
        // 更新本地状态
        const index = this.myImages.findIndex((img: ImageItem) => img.imageId === image.imageId);
        if (index !== -1) {
          this.myImages[index].isLiked = !this.myImages[index].isLiked;
          this.myImages[index].likeCount = (this.myImages[index].likeCount || 0) + (this.myImages[index].isLiked ? 1 : -1);
        }
      }
    } catch (error) {
      console.error('点赞失败:', error);
    }
  }

  /**
   * 加载收藏数量
   */
  async loadFavoriteCount() {
    try {
      // 使用收藏列表API获取真实的收藏数量
      const response = await ApiService.getBookmarkList();
      if (response.code === 1 && response.data) {
        this.favoriteCount = response.data.length || 0;
      } else {
        this.favoriteCount = 0;
      }
    } catch (error) {
      console.error('加载收藏数量失败:', error);
      this.favoriteCount = 0;
    }
  }

  /**
   * 加载浏览记录数量
   */
  async loadHistoryCount() {
    try {
      // 使用浏览记录API获取真实的浏览记录数量
      const response = await ApiService.getBrowsingHistoryList();
      if (response.code === 1 && response.data) {
        this.historyCount = response.data.length || 0;
      } else {
        this.historyCount = 0;
      }
    } catch (error) {
      console.error('加载浏览记录数量失败:', error);
      this.historyCount = 0;
    }
  }

  /**
   * 加载收藏列表
   */
  async loadFavorites(refresh: boolean = false) {
    if (refresh) {
      this.currentPage = 1;
      this.hasMore = true;
      this.myImages = [];
    }

    if (!this.hasMore || this.isLoading) {
      return;
    }

    this.isLoading = true;
    try {
      console.log('开始加载收藏列表...');
      const response = await ApiService.getBookmarkList();
      console.log('收藏列表API响应:', JSON.stringify(response, null, 2));
      
      if (response.code === 1 && response.data) {
        const newImages: ImageItem[] = response.data || [];
        console.log('收藏列表数据:', JSON.stringify(newImages, null, 2));
        
        // 检查每个图片的imageUrl
        newImages.forEach((image, index) => {
          console.log(`收藏图片 ${index}:`, {
            imageId: image.imageId,
            imageName: image.imageName,
            imageUrl: image.imageUrl,
            hasImageUrl: !!image.imageUrl
          });
        });
        
        if (refresh) {
          this.myImages = newImages;
        } else {
          this.myImages = this.myImages.concat(newImages);
        }
        
        // 更新收藏数量
        this.favoriteCount = newImages.length;
        this.hasMore = false; // 收藏列表通常不需要分页
        
        console.log('收藏列表加载完成，数量:', this.myImages.length);
      } else {
        console.error('收藏列表API失败，响应码:', response.code, '错误信息:', response.msg);
      }
    } catch (error) {
      console.error('加载收藏失败:', error);
    } finally {
      this.isLoading = false;
      this.isRefreshing = false;
    }
  }

  /**
   * 加载浏览记录列表
   */
  async loadHistory(refresh: boolean = false) {
    if (refresh) {
      this.currentPage = 1;
      this.hasMore = true;
      this.myImages = [];
    }

    if (!this.hasMore || this.isLoading) {
      return;
    }

    this.isLoading = true;
    try {
      const response = await ApiService.getBrowsingHistoryList();
      if (response.code === 1 && response.data) {
        const newImages: ImageItem[] = response.data || [];
        if (refresh) {
          this.myImages = newImages;
        } else {
          this.myImages = this.myImages.concat(newImages);
        }
        
        // 更新浏览记录数量
        this.historyCount = newImages.length;
        this.hasMore = false; // 浏览记录列表通常不需要分页
      }
    } catch (error) {
      console.error('加载浏览记录失败:', error);
    } finally {
      this.isLoading = false;
      this.isRefreshing = false;
    }
  }

  /**
   * 退出登�?
   */
  /**
   * 删除图片
   */
  async deleteImage(image: ImageItem) {
    promptAction.showDialog({
      title: '确认删除',
      message: `确定要删除图片"${image.imageName}"吗？此操作不可撤销。`,
      buttons: [
        { text: '取消', color: '#999999' },
        { text: '删除', color: '#FF4444' }
      ]
    }).then(async (result) => {
      if (result.index === 1) {
        try {
          console.log('图片对象:', JSON.stringify(image, null, 2));
          // console.log('当前用户图片列表:', this.myImages.map(img => {
          //   const item: ImageListItem = {id: img.imageId, name: img.imageName};
          //   return item;
          // }));
          // console.log('要删除的图片是否在用户列表中:', this.myImages.some(img => img.imageId === image.imageId));

          const response = await ApiService.deleteImage(image.imageId);
          console.log('=== 删除图片响应 ===');
          console.log('删除图片响应:', JSON.stringify(response, null, 2));

          if (response.code === 1) {
            // 从本地列表中移除图片
            this.myImages = this.myImages.filter(img => img.imageId !== image.imageId);
            // 更新图片数量
            this.imageCount = Math.max(0, this.imageCount - 1);
            promptAction.showToast({ message: '图片删除成功' });
            console.log('图片删除成功，当前图片数量:', this.imageCount);
          } else {
            console.error('删除图片失败，响应码:', response.code, '消息:', response.msg);
            console.error('完整响应:', JSON.stringify(response, null, 2));
            promptAction.showToast({ message: `删除失败: ${response.msg || '未知错误'}` });
          }
        } catch (error) {
          console.error('=== 删除图片异常 ===');
          console.error('删除图片异常:', error);
          console.error('错误类型:', typeof error);
          console.error('错误构造函数:', error.constructor.name);
          
          // 尝试获取错误的各种属性
          if (error && typeof error === 'object') {
            console.error('错误属性:', Object.keys(error));
            console.error('错误消息属性:', error.message);
            console.error('错误名称:', error.name);
            console.error('错误堆栈:', error.stack);

            // 尝试手动序列化错误对象
            try {
              const errorStr = JSON.stringify(error, Object.getOwnPropertyNames(error), 2);
              console.error('序列化错误对象:', errorStr);
            } catch (stringifyError) {
              console.error('无法序列化错误对象:', stringifyError);
            }
          }

          // 显示更具体的错误信息
          let errorMessage = '未知错误';
          if (error && typeof error === 'object') {
            const errorObj = error as Error;
            if (errorObj.message) {
              errorMessage = errorObj.message;
            } else if (errorObj.toString) {
              errorMessage = errorObj.toString();
            }
          }
          
          // 尝试使用String()转换
          console.error('错误字符串表示:', String(error));
          console.error('最终错误消息:', errorMessage);
          promptAction.showToast({ message: `删除失败: ${errorMessage}` });
        }
      }
    });
  }

  async logout() {
    promptAction.showDialog({
      title: '确认退出',
      message: '确定要退出登录吗?',
      buttons: [
        { text: '取消', color: '#999999' },
        { text: '确定', color: '#FF4444' }
      ]
    }).then(async (result) => {
      if (result.index === 1) {
        // 清除本地存储的用户信息
        await HttpService.clearToken();
        this.isLoggedIn = false;
        this.myImages = [];
        this.imageCount = 0;
        promptAction.showToast({ message: '已退出登录' });

        // 跳转到登录页面
        router.replaceUrl({ url: 'pages/LoginPage' });
      }
    });
  }

  build() {
    Column() {
      // 顶部导航�?
      if (this.isLoggedIn) {
        // 用户信息卡片 - 更大更好看的样式
        Column({ space: 20 }) {
          Row({ space: 20 }) {
            // 用户头像 - 更大
            Image($r('app.media.tupian'))
              .width(80)
              .height(80)
              .borderRadius(40)
              .objectFit(ImageFit.Cover)
              .shadow({ radius: 8, color: '#1A000000', offsetX: 0, offsetY: 2 })

            // 用户信息 - 更大字体
            Column({ space: 8 }) {
              Text(this.currentUsername)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.Black)
                .alignSelf(ItemAlign.Start)

              Text(this.currentUserAccount || 'user@example.com')
                .fontSize(16)
                .fontColor(Colors.Black60)
                .alignSelf(ItemAlign.Start)

              // 用户状态
              Row({ space: 8 }) {
                Text('●')
                  .fontSize(12)
                  .fontColor('#4CAF50')

                Text('在线')
                  .fontSize(14)
                  .fontColor(Colors.Black60)
              }
              .alignSelf(ItemAlign.Start)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            // 退出按钮 - 更大更好看
            Button('退出')
              .width(60)
              .height(36)
              .backgroundColor('#FF4444')
              .borderRadius(18)
              .fontSize(14)
              .fontColor(Color.White)
              .onClick(() => this.logout())
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          // 用户统计信息
          Row({ space: 24 }) {
            Column({ space: 4 }) {
              Text('作品')
                .fontSize(12)
                .fontColor(Colors.Black60)
              
              Text(`${this.imageCount}`)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.Black)
            }
            .alignItems(HorizontalAlign.Center)

            Column({ space: 4 }) {
              Text('收藏')
                .fontSize(12)
                .fontColor(Colors.Black60)
              
              Text(`${this.favoriteCount}`)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.Black)
            }
            .alignItems(HorizontalAlign.Center)

            Column({ space: 4 }) {
              Text('浏览')
                .fontSize(12)
                .fontColor(Colors.Black60)
              
              Text(`${this.historyCount}`)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.Black)
            }
            .alignItems(HorizontalAlign.Center)
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceEvenly)
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 24, bottom: 24 })
        .backgroundColor(Color.White)
        .borderRadius(20)
        .margin({ left: 16, right: 16, top: 16, bottom: 32 })
        .shadow({ radius: 12, color: '#1A000000', offsetX: 0, offsetY: 4 })

        // 作品/收藏/浏览记录切换
        Row({ space: 0 }) {
          Text('我的作品')
            .fontSize(16)
            .fontWeight(this.currentTab === 'works' ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.currentTab === 'works' ? '#4CAF50' : Colors.Black60)
            .padding({ top: 12, bottom: 12, left: 20, right: 20 })
            .onClick(() => {
              this.currentTab = 'works';
              this.loadMyImages(true);
            })

          Text('我的收藏')
            .fontSize(16)
            .fontWeight(this.currentTab === 'favorites' ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.currentTab === 'favorites' ? '#4CAF50' : Colors.Black60)
            .padding({ top: 12, bottom: 12, left: 20, right: 20 })
            .onClick(() => {
              this.currentTab = 'favorites';
              this.loadFavorites(true);
              this.loadFavoriteCount();
            })

          Text('浏览记录')
            .fontSize(16)
            .fontWeight(this.currentTab === 'history' ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.currentTab === 'history' ? '#4CAF50' : Colors.Black60)
            .padding({ top: 12, bottom: 12, left: 20, right: 20 })
            .onClick(() => {
              this.currentTab = 'history';
              this.loadHistory(true);
              this.loadHistoryCount();
            })
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .backgroundColor(Color.White)
        .borderRadius({ topLeft: 20, topRight: 20 })
        .shadow({ radius: 8, color: '#1A000000', offsetX: 0, offsetY: -2 })
      }

      if (!this.isLoggedIn) {
        // 未登录状�?
        Column({ space: 24 }) {
          // 用户头像
          Image($r('app.media.wode'))
            .width(80)
            .height(80)
            .margin({ top: 60 })

          Text('未登录')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.Black)

          Text('登录后查看你的作品和收藏')
            .fontSize(14)
            .fontColor(Colors.Black60)

          Button('立即登录')
            .width(200)
            .height(40)
            .backgroundColor('#4CAF50')
            .borderRadius(20)
            .fontSize(16)
            .fontColor(Color.Black)
            .onClick(() => this.navigateToLogin())
            .margin({ top: 24 })
        }
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
      } else {
        // 已登录状态 - 内容区域
        Column() {
          if (this.currentTab === 'works') {
            // 我的作品 - 直接显示图片列表
          } else {
            // 我的收藏 - 直接显示图片列表
          }

          // 我的作品列表
          if (this.myImages.length === 0 && !this.isLoading) {
            // 空状�?
            Column({ space: 16 }) {
              if (this.currentTab === 'works') {
                // 我的作品空状态 - 显示图标
                Text('📭')
                  .fontSize(80)
                  .opacity(0.6)
                // 我的作品空状态
                Text('还没有作品')
                  .fontSize(16)
                  .fontColor(Colors.Black60)

                Text('快去上传你的第一张图片吧')
                  .fontSize(14)
                  .fontColor(Colors.Black40)

                Button('上传图片')
                  .width(120)
                  .height(36)
                  .backgroundColor('#4CAF50')
                  .borderRadius(18)
                  .fontSize(14)
                  .fontColor(Color.Black)
                  .onClick(() => this.navigateToUpload())
              } else if (this.currentTab === 'favorites') {
                // 我的收藏空状态 - 只显示简单提示
                Text('暂无收藏作品')
                  .fontSize(16)
                  .fontColor(Colors.Black60)
              } else {
                // 浏览记录空状态 - 只显示简单提示
                Text('暂无浏览记录')
                  .fontSize(16)
                  .fontColor(Colors.Black60)
              }
            }
            .justifyContent(FlexAlign.Center)
            .layoutWeight(1)
          } else {
            // 图片网格 - 添加刷新功能
            Refresh({ refreshing: this.isRefreshing }) {
              Grid() {
                ForEach(this.myImages, (image: ImageItem, index: number) => {
                  GridItem() {
                    Column() {
                      // 图片
                      if (image.imageUrl) {
                        Image(image.imageUrl)
                          .width('100%')
                          .height(200)
                          .borderRadius(12)
                          .objectFit(ImageFit.Cover)
                          .onClick(() => {
                            // 跳转到图片详情页面，传递完整的图片数据
                            console.log('点击图片，准备跳转到详情页面，图片ID:', image.imageId);
                            router.pushUrl({ 
                              url: 'pages/ImageDetailPage',
                              params: { 
                                imageId: image.imageId,
                                imageData: JSON.stringify(image) // 传递完整的图片数据
                              }
                            }).then(() => {
                              console.log('跳转成功');
                            }).catch((error: Error) => {
                              console.error('跳转失败:', error);
                            });
                          })
                      } else {
                        // 如果没有imageUrl，显示占位符
                        Column() {
                          Text('📷')
                            .fontSize(48)
                            .opacity(0.5)
                          Text('图片加载中...')
                            .fontSize(12)
                            .fontColor(Colors.Black40)
                            .margin({ top: 8 })
                        }
                        .width('100%')
                        .height(200)
                        .justifyContent(FlexAlign.Center)
                        .backgroundColor(Colors.White10)
                        .borderRadius(12)
                        .onClick(() => {
                          console.log('点击占位符图片，图片ID:', image.imageId, '图片名称:', image.imageName);
                        })
                      }

                      // 图片信息
                      Column({ space: 8 }) {
                        Text(image.imageName)
                          .fontSize(14)
                          .fontWeight(FontWeight.Medium)
                          .fontColor(Color.Black)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })

                        Row() {
                          Text(this.currentUsername)
                            .fontSize(12)
                            .fontColor(Colors.Black60)

                          Blank()

                          Row({ space: 4 }) {
                            Text(image.isLiked ? '❤️' : '🤍')
                              .fontSize(16)
                              .onClick(() => this.toggleLike(image))

                            Text((image.likeCount || 0).toString())
                              .fontSize(12)
                              .fontColor(Colors.Black60)
                          }
                        }
                      }
                      .width('100%')
                      .padding({ top: 8, left: 8, right: 8, bottom: 8 })
                    }
                    .width('100%')
                    .backgroundColor(Colors.White10)
                    .borderRadius(12)
                    .padding(8)
                    .onTouch((event: TouchEvent) => {
                      if (event.type === TouchType.Down) {
                        this.deleteImage(image);
                      }
                    })
                  }
                })
              }
              .columnsTemplate('1fr 1fr')
              .rowsGap(12)
              .columnsGap(12)
              .padding(16)
              .onScrollIndex(() => {
                this.loadMore();
              })
            }
            .layoutWeight(1)

            // 加载更多指示器
            if (this.isLoading) {
              Row() {
                LoadingProgress()
                  .width(20)
                  .height(20)
                  .color(Color.White)

                Text('加载中...')
                  .fontSize(12)
                  .fontColor(Colors.Black60)
                  .margin({ left: 8 })
              }
              .justifyContent(FlexAlign.Center)
              .width('100%')
              .height(40)
            }
          }
        }
        .layoutWeight(1)
      }

      // 底部导航栏
      BottomNavBar({ currentPage: 'profile' })
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
