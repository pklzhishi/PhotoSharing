import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { ImageItem } from '../models/Image';
import { ApiService } from '../services/ApiService';
import { Colors } from '../common/Colors';
import { BottomNavBar } from '../common/BottomNavBar';

/**
 * 图片分享主页
 */
@Entry
@Component
struct Index {
  @State images: ImageItem[] = [];
  @State isLoading: boolean = false;
  @State isRefreshing: boolean = false;
  @State searchText: string = '';
  @State isSearching: boolean = false;
  @State showSearchInput: boolean = false;

  /**
   * 去掉文件后缀，只显示图片名称
   */
  private getDisplayImageName(imageName: string): string {
    if (!imageName) return '';
    // 找到最后一个点的位置
    const lastDotIndex = imageName.lastIndexOf('.');
    if (lastDotIndex === -1) {
      // 没有后缀，直接返回
      return imageName;
    }
    // 返回点之前的部分
    return imageName.substring(0, lastDotIndex);
  }

  aboutToAppear() {
    this.loadImages();
  }

  /**
   * 加载图片数据
   */
  async loadImages() {
    this.isLoading = true;
    try {
      console.log('开始加载图片数据...');
      const response = await ApiService.getRandomImages(8);
      console.log('API响应:', JSON.stringify(response, null, 2));
      
      if (response.code === 1) {
        this.images = response.data || [];
        console.log('图片加载成功，数量:', this.images.length);
      } else {
        console.error('API返回错误，code:', response.code, 'msg:', response.msg);
        this.images = [];
      }
    } catch (error) {
      console.error('加载图片失败:', error);
      this.images = [];
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
   * 切换搜索输入框显示状态
   */
  toggleSearchInput() {
    this.showSearchInput = !this.showSearchInput;
    if (!this.showSearchInput) {
      // 如果隐藏搜索框，清空搜索内容并重新加载图片
      this.searchText = '';
      this.loadImages();
    }
  }

  /**
   * 执行搜索
   */
  async performSearch() {
    if (!this.searchText.trim()) {
      promptAction.showToast({ message: '请输入搜索关键词' });
      return;
    }

    this.isSearching = true;
    try {
      console.log('开始搜索图片，关键词:', this.searchText);
      const response = await ApiService.searchImages(this.searchText);
      console.log('搜索响应:', JSON.stringify(response, null, 2));
      
      if (response.code === 1) {
        this.images = response.data || [];
        console.log('搜索成功，找到图片数量:', this.images.length);
        if (this.images.length === 0) {
          promptAction.showToast({ message: '未找到相关图片' });
        }
      } else {
        console.error('搜索失败，响应码:', response.code, '错误信息:', response.msg);
        promptAction.showToast({ message: '搜索失败，请重试' });
      }
    } catch (error) {
      console.error('搜索异常:', error);
      promptAction.showToast({ message: '搜索失败，请检查网络连接' });
    } finally {
      this.isSearching = false;
    }
  }

  /**
   * 清空搜索
   */
  clearSearch() {
    this.searchText = '';
    this.showSearchInput = false;
    this.loadImages();
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
        Text('拾光映画')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Black)

        Blank()

        // 搜索按钮
        Image($r('app.media.sousuo'))
          .width(24)
          .height(24)
          .onClick(() => this.toggleSearchInput())
      }
      .width('100%')
      .height(56)
      .padding({ left: 20, right: 20 })
      .backgroundColor(Color.Transparent)

      // 搜索输入框
      if (this.showSearchInput) {
        Row({ space: 8 }) {
          TextInput({ placeholder: '搜索图片...' })
            .layoutWeight(1)
            .height(40)
            .backgroundColor(Color.White)
            .borderRadius(20)
            .fontSize(14)
            .fontColor(Color.Black)
            .placeholderColor(Colors.Black40)
            .onChange((value: string) => {
              this.searchText = value;
            })
            .onSubmit(() => {
              this.performSearch();
            })

          Button('搜索')
            .width(60)
            .height(40)
            .backgroundColor('#4CAF50')
            .fontColor(Color.White)
            .borderRadius(20)
            .fontSize(14)
            .enabled(!this.isSearching)
            .onClick(() => this.performSearch())

          Button('取消')
            .width(60)
            .height(40)
            .backgroundColor('#F5F5F5')
            .fontColor(Color.Black)
            .borderRadius(20)
            .fontSize(14)
            .onClick(() => this.clearSearch())
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 8 })
      }

      // 图片网格
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
        .layoutWeight(1)
      } else if (this.images.length === 0) {
        // 无图片状态
        Column() {
          Image($r('app.media.tupian'))
            .width(80)
            .height(80)
            .margin({ bottom: 16 })
          
          Text('请登录浏览作品')
            .fontSize(18)
            .fontColor(Color.Black)
            .margin({ bottom: 8 })
          
          Text('登录后即可查看精彩内容')
            .fontSize(14)
            .fontColor(Colors.Black60)
            .margin({ bottom: 24 })
          
          Button('立即登录')
            .width(120)
            .height(40)
            .backgroundColor('#4CAF50')
            .fontColor(Color.White)
            .borderRadius(20)
            .onClick(() => {
              router.pushUrl({ url: 'pages/LoginPage' });
            })
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .layoutWeight(1)
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
                    .onClick(async () => {
                      // 跳转到图片详情页面，传递完整的图片数据
                      console.log('点击图片，准备跳转到详情页面，图片ID:', image.imageId);
                      
                      try {
                        // 调用获取图片信息接口，记录浏览记录
                        console.log('调用获取图片信息接口，记录浏览记录...');
                        const infoResponse = await ApiService.getImageInformation(image.imageId);
                        console.log('获取图片信息响应:', JSON.stringify(infoResponse, null, 2));
                        
                        if (infoResponse.code === 1 && infoResponse.data) {
                          console.log('浏览记录已记录，图片信息:', infoResponse.data);
                          // 使用从接口获取的最新图片信息
                          router.pushUrl({ 
                            url: 'pages/ImageDetailPage',
                            params: { 
                              imageId: image.imageId,
                              imageData: JSON.stringify(infoResponse.data) // 使用最新的图片数据
                            }
                          }).then(() => {
                            console.log('跳转成功');
                          }).catch((error: Error) => {
                            console.error('跳转失败:', error);
                          });
                        } else {
                          console.warn('获取图片信息失败，使用原有数据跳转');
                          // 如果接口失败，使用原有数据跳转
                          router.pushUrl({ 
                            url: 'pages/ImageDetailPage',
                            params: { 
                              imageId: image.imageId,
                              imageData: JSON.stringify(image) // 使用原有图片数据
                            }
                          }).then(() => {
                            console.log('跳转成功');
                          }).catch((error: Error) => {
                            console.error('跳转失败:', error);
                          });
                        }
                      } catch (error) {
                        console.error('调用获取图片信息接口失败:', error);
                        // 如果接口调用失败，仍然跳转到详情页面
                        router.pushUrl({ 
                          url: 'pages/ImageDetailPage',
                          params: { 
                            imageId: image.imageId,
                            imageData: JSON.stringify(image) // 使用原有图片数据
                          }
                        }).then(() => {
                          console.log('跳转成功');
                        }).catch((error: Error) => {
                          console.error('跳转失败:', error);
                        });
                      }
                    })

                  // 图片信息
                  Column({ space: 8 }) {
                    Text(this.getDisplayImageName(image.imageName))
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
                  .padding({ top: 8, left: 8, right: 8, bottom: 5 })
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
          .padding({ top: 3, left: 16, right: 16, bottom: 16 })
          .onScrollIndex(() => {
            // 可以在这里实现分页加载
          })
        }
        .onRefreshing(() => {
          this.refreshImages();
        })
        .layoutWeight(1)
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