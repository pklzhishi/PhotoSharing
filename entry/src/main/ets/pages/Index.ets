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
  @State isSearchMode: boolean = false;
  @State searchQuery: string = '';
  @State searchBarPercent: number = 0; // 0~1 控制搜索框宽度动画（保留无需使用）
  @State searchWidthPx: number = 0;    // 像素宽度动画，避免把图标挤没

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

  /** 进入搜索模式 */
  enterSearchMode() {
    if (this.isSearchMode) {
      return;
    }
    this.isSearchMode = true;
    this.searchWidthPx = 0;
    animateTo({ duration: 200 }, () => {
      this.searchWidthPx = 220; // 目标宽度
    });
  }

  /** 退出搜索模式并清理 */
  exitSearchMode(clear: boolean = false) {
    if (!this.isSearchMode) {
      return;
    }
    animateTo({ duration: 200 }, () => {
      this.searchWidthPx = 0;
    });
    this.isSearchMode = false;
    if (clear) {
      this.searchQuery = '';
    }
  }

  /** 执行搜索并跳转到搜索结果页 */
  doSearch() {
    const q = (this.searchQuery || '').trim();
    if (!q) {
      this.exitSearchMode(false);
      return;
    }
    console.log('点击搜索')
    // 对中文等特殊字符进行URL编码
    const encodedQuery = encodeURIComponent(q);
    console.log('编码后搜索值:', encodedQuery);
    router.pushUrl({ url: 'pages/SearchPage', params: { query: q } });
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

        // 右侧：普通模式显示图标，搜索模式显示搜索框
        if (!this.isSearchMode) {
          Text('图片分享')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.Black)

          Blank()
          Row({ space: 15 }) {
            // Text('🔍')
            //   .fontSize(24)
            //   .fontColor(Color.Black)
            //   .onClick(() => this.enterSearchMode())
            Image($r('app.media.sousuo'))
              .width(24)
              .onClick(() => this.enterSearchMode())
            Text('📤')
              .fontSize(24)
              .fontColor(Color.Black)
              .onClick(() => this.navigateToUpload())

            Text('👤')
              .fontSize(24)
              .fontColor(Color.Black)
              .onClick(() => this.navigateToProfile())
          }
        } else {

          Row({ space: 10 }) {
            TextInput({ placeholder: '搜索图片名称...', text: this.searchQuery })
              .fontSize(15)
              .onChange((v: string) => this.searchQuery = v)
              .width(this.searchWidthPx > 220 ? 220 : this.searchWidthPx)
              .height(36)
              .borderRadius(18)
              .backgroundColor('#FFFFFF')
              .borderRadius(18)
              // 更淡的边框色，减少视觉重量
              .border({ width: 1, color: Colors.Black10})
              // 添加柔和阴影效果
              .shadow({
                radius: 4,      // 阴影模糊半径
                color: '#00000010', // 半透明黑色阴影
                offsetX: 0,     // 水平偏移
                offsetY: 2      // 垂直偏移，营造轻微上浮感
              })
              .padding({ left: 12, right: 12 })
              .enterKeyType(EnterKeyType.Search)
              .onSubmit(() => this.doSearch())
              .margin({left:30})

            // 搜索提交按钮（保持可见）
            Image($r('app.media.sousuo'))
              // .fontSize(22)
              // .fontColor(Color.Black)
              .width(24)
              .onClick(() => this.doSearch())

            // 退出搜索模式
            Text('✖')
              .fontSize(20)
              .fontColor(Colors.Black60)
              .onClick(() => this.exitSearchMode(false))
          }
        }
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.Transparent)

      // 点击空白区域可退出搜索模式
      if (this.isSearchMode) {
        Blank()
          .width('100%')
          .height(1) // 占位即可，下面区域也可点击
      }

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