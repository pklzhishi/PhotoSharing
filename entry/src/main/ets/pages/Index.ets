import router from '@ohos.router';
import { ImageItem } from '../models/Image';
import { ApiService } from '../services/ApiService';
import { Colors } from '../common/Colors';

/**
 * 图片分享主页
 */
@Entry
@Component
struct Index {
  @State images: ImageItem[] = [];
  @State isLoading: boolean = false;
  @State isRefreshing: boolean = false;

  aboutToAppear() {
    this.loadImages();
  }

  /**
   * 加载图片数据
   */
  async loadImages() {
    this.isLoading = true;
    try {
      const response = await ApiService.getRandomImages(8);
      if (response.code === 1) {
        this.images = response.data || [];
      }
    } catch (error) {
      console.error('加载图片失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 刷新图片
   */
  async refreshImages() {
    this.isRefreshing = true;
    await this.loadImages();
    this.isRefreshing = false;
  }

  /**
   * 跳转到登录页面
   */
  navigateToLogin() {
    router.pushUrl({ url: 'pages/LoginPage' });
  }

  /**
   * 跳转到上传页面
   */
  navigateToUpload() {
    router.pushUrl({ url: 'pages/UploadPage' });
  }

  /**
   * 跳转到个人中心
   */
  navigateToProfile() {
    router.pushUrl({ url: 'pages/ProfilePage' });
  }

  /**
   * 点赞/取消点赞
   */
  async toggleLike(image: ImageItem) {
    try {
      const response = await ApiService.toggleLike(image.imageId);
      if (response.code === 1) {
        // 更新本地状态
        const index = this.images.findIndex((img: ImageItem) => img.imageId === image.imageId);
        if (index !== -1) {
          this.images[index].isLiked = !this.images[index].isLiked;
          this.images[index].likeCount = (this.images[index].likeCount || 0) + (this.images[index].isLiked ? 1 : -1);
        }
      }
    } catch (error) {
      console.error('点赞失败:', error);
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('图片分享')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Black)

        Blank()

        Row({ space: 15 }) {
          Text('📤')
            .fontSize(24)
            .fontColor(Color.Black)
            .onClick(() => this.navigateToUpload())

          Text('👤')
            .fontSize(24)
            .fontColor(Color.Black)
            .onClick(() => this.navigateToProfile())
        }
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.Transparent)

      // 图片网格
      if (this.isLoading && this.images.length === 0) {
        // 加载中状态
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
            .color(Color.White)
          
          Text('加载中...')
            .fontSize(16)
            .fontColor(Color.Black)
            .margin({ top: 16 })
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .height('100%')
      } else {
        // 图片列表
        Refresh({ refreshing: this.isRefreshing }) {
          Grid() {
            ForEach(this.images, (image: ImageItem, index: number) => {
              GridItem() {
                Column() {
                  // 图片
                  Image(image.imageUrl)
                    .width('100%')
                    .height(200)
                    .borderRadius(12)
                    .objectFit(ImageFit.Cover)
                    .onClick(() => {
                      // 点击图片可以查看大图
                    })

                  // 图片信息
                  Column({ space: 8 }) {
                    Text(image.imageName)
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(Color.Black)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })

                    Row() {
                      Text(image.username || '匿名用户')
                        .fontSize(12)
                        .fontColor(Colors.Black60)

                      Blank()

                      Row({ space: 4 }) {
                        Text(this.images[index].isLiked ? '❤️' : '🤍')
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
              }
            })
          }
          .columnsTemplate('1fr 1fr')
          .rowsGap(12)
          .columnsGap(12)
          .padding(16)
          .onScrollIndex(() => {
            // 可以在这里实现分页加载
          })
        }
        .onRefreshing(() => {
          this.refreshImages();
        })
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