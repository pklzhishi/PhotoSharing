import router from '@ohos.router';
import { ApiService } from '../services/ApiService';
import { ImageItem } from '../models/Image';
import { Colors } from '../common/Colors';
import promptAction from '@ohos.promptAction';
@Entry
@Component
struct SearchPage {
  @State query: string = '';
  @State results: ImageItem[] = [];
  @State loading: boolean = false;
  @State isRefreshing: boolean = false; // 下拉刷新状态

  aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    const q = (params?.query as string) || '';
    console.log('搜索值：'+q)
    // const params = router.getParams() as Record<string, string>;
    // // 接收参数时进行URL解码
    // const encodedQ = (params?.query as string) || '';
    // const q = decodeURIComponent(encodedQ);  // 解码中文参数

    console.log('接收并解码后的搜索值:', q);
    this.query = q;
    this.search(q);
  }

  async search(q: string, isRefresh: boolean = false) {
    if (!q) { return; }
    if (!isRefresh) {
      this.loading = true;
    }
    try {
      const res = await ApiService.searchImage(q);
      if (res.code === 1) {
        this.results = res.data || [];
        console.log("搜索结果:", this.results)
      }
    } catch (e) {
      console.error('搜索失败:', e);
    } finally {
      this.loading = false;
      this.isRefreshing = false; // 结束刷新状态
    }
  }

  // 切换点赞状态
  toggleLike(image: ImageItem) {
    const index = this.results.findIndex(item => item.imageId === image.imageId);
    if (index !== -1) {
      // 更新点赞状态
      this.results[index].isLiked = !this.results[index].isLiked;
      // 更新点赞数量
      this.results[index].likeCount = (this.results[index].likeCount || 0) + (this.results[index].isLiked ? 1 : -1);
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('←')
          .fontSize(24)
          .onClick(() => router.back())

        Text(`搜索：${this.query}`)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 8 })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })

      if (this.loading) {
        Column() {
          LoadingProgress().width(40).height(40)
          Text('加载中...').margin({ top: 12 })
        }.justifyContent(FlexAlign.Center).width('100%').height('100%')
      } else if (this.results.length === 0) {
        Column() {
          Text('未找到相关图片').fontColor(Colors.Black60)
        }.justifyContent(FlexAlign.Center).width('100%').height('100%')
      } else {
        // 下拉刷新组件
        Refresh({
          refreshing: this.isRefreshing,
          // onRefresh: () => {
          //   // 下拉刷新时重新加载数据
          //   this.isRefreshing = true;
          //   this.search(this.query, true);
          // }
        }) {
          Grid() {
            ForEach(this.results, (image: ImageItem, index: number) => {
              GridItem() {
                Column() {
                  // 图片
                  Image(image.imageUrl)
                    .width('100%')
                    .height(200)
                    .borderRadius(12)
                    .objectFit(ImageFit.Cover)
                    .onClick(() => {
                      // 点击图片查看大图（可添加跳转逻辑）
                      router.pushUrl({
                        url: '../imageDetail/ImageDetailPage',
                        params: { image: image }
                      });
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
              }
            })
          }
          .columnsTemplate('1fr 1fr')
          .rowsGap(12)
          .columnsGap(12)
          .padding(16)
          .onScrollIndex((first, last) => {
            // 分页加载逻辑：当滚动到倒数第2个item时加载更多
            if (last >= this.results.length - 2 && !this.loading) {
              console.log("准备加载更多数据");
              // 这里可以添加加载更多的逻辑
              // this.loadMoreData();
            }
          })
        }
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
