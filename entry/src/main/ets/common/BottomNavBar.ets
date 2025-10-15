import router from '@ohos.router';

/**
 * 底部导航栏组件
 */
@Component
export struct BottomNavBar {
  @Prop currentPage: string; // 由父页面传入当前页面状态

  /**
   * 切换到首页
   */
  navigateToHome() {
    router.replaceUrl({ url: 'pages/Index' });
    this.currentPage = 'home';
  }

  /**
   * 切换到上传页面
   */
  navigateToUpload() {
    router.replaceUrl({ url: 'pages/UploadPage' });
    this.currentPage = 'upload';
  }

  /**
   * 切换到个人中心
   */
  navigateToProfile() {
    router.replaceUrl({ url: 'pages/ProfilePage' });
    this.currentPage = 'profile';
  }

  build() {
    Row() {
      // 首页
      Column({ space: 4 }) {
        Image($r('app.media.shouye'))
          .width(24)
          .height(24)
          .opacity(this.currentPage === 'home' ? 1.0 : 0.6)
        
        Text('首页')
          .fontSize(12)
          .fontColor(this.currentPage === 'home' ? '#4CAF50' : '#999999')
      }
      .onClick(() => this.navigateToHome())
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .padding({ top: 8, bottom: 8 })

      // 添加按钮
      Column() {
        Button() {
          Text('+')
            .fontSize(24)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
        }
        .width(56)
        .height(56)
        .backgroundColor('#4CAF50')
        .borderRadius(28)
        .onClick(() => this.navigateToUpload())
      }
      .justifyContent(FlexAlign.Center)
      .padding({ top: 8, bottom: 8 })

      // 个人中心
      Column({ space: 4 }) {
        Image($r('app.media.wode'))
          .width(24)
          .height(24)
          .opacity(this.currentPage === 'profile' ? 1.0 : 0.6)
        
        Text('我的')
          .fontSize(12)
          .fontColor(this.currentPage === 'profile' ? '#4CAF50' : '#999999')
      }
      .onClick(() => this.navigateToProfile())
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .padding({ top: 8, bottom: 8 })
    }
    .width('100%')
    .height(80)
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 20, topRight: 20 })
    .shadow({
      radius: 10,
      color: 'rgba(0, 0, 0, 0.1)',
      offsetX: 0,
      offsetY: -2
    })
  }
}

