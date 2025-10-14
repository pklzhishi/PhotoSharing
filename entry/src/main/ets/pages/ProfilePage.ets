import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { ImageItem, PageRequest, PageResponse } from '../models/Image';
import { ApiService } from '../services/ApiService';
import { HttpService } from '../services/HttpService';
import { Colors } from '../common/Colors';

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

  aboutToAppear() {
    this.loadUserInfo();
    this.loadMyImages(true);
  }

  onPageShow() {
    // 页面显示时重新加载用户信息，确保登录状态更新后能刷新页面
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
        return;
      }

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
        this.isLoggedIn = true;
        console.log('用户已登录，图片数量:', this.imageCount);
        console.log('响应数据结构 - code:', response.code, 'data:', response.data, 'msg:', response.msg);
      } else {
        this.isLoggedIn = false;
        this.imageCount = 0;
        console.error('获取图片数量失败，响应码:', response.code, '消息:', response.msg);
      }
    } catch (error) {
      console.error('加载用户信息失败:', error);
      this.isLoggedIn = false;
      this.imageCount = 0;
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
          console.log('=== 删除图片开始 ===');
          console.log('图片ID:', image.imageId);
          console.log('图片名称:', image.imageName);
          console.log('图片对象:', JSON.stringify(image, null, 2));
          console.log('当前用户图片列表:', this.myImages.map(img => {
            const item: ImageListItem = {id: img.imageId, name: img.imageName};
            return item;
          }));
          console.log('要删除的图片是否在用户列表中:', this.myImages.some(img => img.imageId === image.imageId));
          
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
        // 清除本地存储的用户信�?
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
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor(Color.Black)
          .onClick(() => this.goBack())

        Text('个人中心')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Black)
          .margin({ left: 16 })

        Blank()

        if (this.isLoggedIn) {
          Text('退出')
            .fontSize(14)
            .fontColor('#FF4444')
            .onClick(() => this.logout())
        }
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.Transparent)

      if (!this.isLoggedIn) {
        // 未登录状�?
        Column({ space: 24 }) {
          // 用户头像
          Text('👤')
            .fontSize(80)
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
        // 已登录状态
        Column() {
          // 用户信息区域
          Column({ space: 16 }) {
            // 用户头像和基本信息
            Row({ space: 16 }) {
              Text('👤')
                .fontSize(60)

              Column({ space: 4 }) {
                Text('我的作品')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.Black)

                Text(`${this.imageCount} 张图片`)
                  .fontSize(14)
                  .fontColor(Colors.Black60)
              }
              .alignItems(HorizontalAlign.Start)

              Blank()

              Button('上传')
                .width(60)
                .height(32)
                .backgroundColor('#4CAF50')
                .borderRadius(16)
                .fontSize(12)
                .fontColor(Color.Black)
                .onClick(() => this.navigateToUpload())
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Colors.White10)
            .borderRadius(12)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16 })

          // 我的作品列表
          if (this.myImages.length === 0 && !this.isLoading) {
            // 空状�?
            Column({ space: 16 }) {
              Text('📭')
                .fontSize(80)
                .opacity(0.6)

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
            }
            .justifyContent(FlexAlign.Center)
            .layoutWeight(1)
          } else {
            // 图片网格 - 添加刷新功能
            Refresh({ refreshing: this.isRefreshing }) {
              Column() {
                Grid() {
              ForEach(this.myImages, (image: ImageItem) => {
                GridItem() {
                  Column() {
                    Image(image.imageUrl)
                      .width('100%')
                      .height(120)
                      .borderRadius(8)
                      .objectFit(ImageFit.Cover)

                    Text(image.imageName)
                      .fontSize(12)
                      .fontColor(Color.White)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .margin({ top: 4 })
                  }
                  .width('100%')
                  .backgroundColor(Colors.White10)
                  .borderRadius(8)
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
            .layoutWeight(1)
            .onScrollIndex(() => {
              this.loadMore();
            })

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
              .width('100%')
              .height('100%')
            }
            .onRefreshing(() => {
              this.refreshData();
            })
          }
        }
        .layoutWeight(1)
      }
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
