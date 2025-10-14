import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { LoginRequest } from '../models/User';
import { ApiService } from '../services/ApiService';
import { Colors } from '../common/Colors';
import {HttpService} from '../services/HttpService'
// ArkUI 内置枚举从全局命名空间获取，避免引入不存在的包


/** 登录页面 */
@Entry
@Component
struct LoginPage {
  @State userAccount: string = '';
  @State password: string = '';
  @State isLoading: boolean = false;
  @State isLoggedIn: boolean = false;

  /** 登录处理 */
  async login() {
    if (!this.userAccount.trim()) {
      promptAction.showToast({ message: '请输入账号' });
      return;
    }
    if (!this.password.trim()) {
      promptAction.showToast({ message: '请输入密码' });
      return;
    }

    this.isLoading = true;
    try {
      const request: LoginRequest = {
        userAccount: this.userAccount.trim(),
        password: this.password.trim()
      };

      const response = await ApiService.login(request);
      if (response.code === 1 && response.data && response.data.token) {
        promptAction.showToast({ message: '登录成功' });
        // 保存用户信息和token
        HttpService.saveToken(response.data.token);

        // 跳转到主页并替换当前页面
        router.replaceUrl({ url: 'pages/Index' });
      } else {
        promptAction.showToast({ message: response.msg || '登录失败' });
      }
    } catch (error) {
      console.error('登录失败:', error);
      promptAction.showToast({ message: '登录失败，请检查网络连接' });
    } finally {
      this.isLoading = false;
    }
  }

  /** 检查登录状态 */
  async checkLoginStatus() {
    try {
      const token = await HttpService.getToken();
      this.isLoggedIn = !!token;
      if (this.isLoggedIn) {
        // 如果已登录，直接跳转到主页
        router.replaceUrl({ url: 'pages/Index' });
      }
    } catch (error) {
      console.error('检查登录状态失败:', error);
      this.isLoggedIn = false;
    }
  }

  /** 页面显示时检查登录状态 */
  onPageShow() {
    this.checkLoginStatus();
  }

  /** 跳转到注册页面 */
  navigateToRegister() {
    router.pushUrl({ url: 'pages/RegisterPage' });
  }

  // navigateToIndex() {
  //   router.pushUrl( {url: 'pages/Index'} )
  // }

  /** 返回上一页 */
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

        Text('登录')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Black)
          .margin({ left: 16 })

        Blank()
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.Transparent)

      // 登录表单
      Column() {
        // Logo区域
        Column({ space: 16 }) {

          Image($r('app.media.tupian'))
            .width('30%')
          Text('拾光映画')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.Black)

          Text('分享美好瞬间，记录精彩生活')
            .fontSize(14)
            .fontColor(Colors.Black60)
        }
        .margin({top:-100, bottom: 40 })

        // 输入表单
        Column({ space: 16 }) {
          // 账号输入框
          Column({ space: 8 }) {
            TextInput({ placeholder: '请输入账号' })
              .width('100%')
              .height(48)
              .backgroundColor(Colors.White20)
              .borderRadius(8)
              .fontSize(16)
              .fontColor(Color.Black)
              .placeholderColor(Colors.Black40)
              .onChange((value: string) => {
                this.userAccount = value;
              })
          }

          // 密码输入框
          Column({ space: 8 }) {
            TextInput({ placeholder: '请输入密码' })
              .width('100%')
              .height(48)
              .backgroundColor(Colors.White20)
              .borderRadius(8)
              .fontSize(16)
              .fontColor(Color.Black)
              .placeholderColor(Colors.Black40)
              .type(InputType.Password)
              .onChange((value: string) => {
                this.password = value;
              })
          }
        }
        .width('100%')

        // 登录按钮
        Button(this.isLoading ? '登录中...' : '登录')
          .width('100%')
          .height(48)
          .backgroundColor('#4CAF50')
          .borderRadius(8)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.Black)
          .enabled(!this.isLoading)
          .onClick(() => this.login())
          .margin({top:20})

        // 注册链接
        Row() {
          Text('还没有账号？')
            .fontSize(14)
            .fontColor(Colors.Black60)

          Text('立即注册')
            .fontSize(14)
            .fontColor('#4CAF50')
            .fontWeight(FontWeight.Medium)
            .onClick(() => this.navigateToRegister())
        }
        .margin({ top: 16 })
      }
      .width('100%')
      .padding({ left: 32, right: 32 })
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
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

