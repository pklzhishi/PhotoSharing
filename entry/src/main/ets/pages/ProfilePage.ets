import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { ImageItem, PageRequest, PageResponse } from '../models/Image';
import { ApiService } from '../services/ApiService';
import { HttpService } from '../services/HttpService';
import { Colors } from '../common/Colors';

/**
 * 个人中心页面
 */
@Entry
@Component
struct ProfilePage {
  @State myImages: ImageItem[] = [];
  @State imageCount: number = 0;
  @State isLoading: boolean = false;
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
      if (!token) {
        this.isLoggedIn = false;
        this.imageCount = 0;
        return;
      }

      const response = await ApiService.getMyImageCount();
      if (response.code === 1) {
        this.imageCount = response.data || 0;
        this.isLoggedIn = true;
      } else {
        this.isLoggedIn = false;
        this.imageCount = 0;
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

      const response = await ApiService.getMyImages(request);
      if (response.code === 1) {
        const pageData = response.data as PageResponse<ImageItem>;
        if (refresh) {
          this.myImages = pageData.records || [];
        } else {
          this.myImages = [...this.myImages, ...(pageData.records || [])];
        }
        this.hasMore = this.currentPage < pageData.pages;
      }
    } catch (error) {
      console.error('加载我的图片失败:', error);
    } finally {
      this.isLoading = false;
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
            // 图片网格
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

            // 加载更多指示�?
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
