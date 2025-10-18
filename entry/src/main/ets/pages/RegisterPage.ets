// import router from '@ohos.router';
// import promptAction from '@ohos.promptAction';
// import { RegisterRequest } from '../models/User';
// import { ApiService } from '../services/ApiService';
// import { Colors } from '../common/Colors';
//
// /**
//  * 注册页面
//  */
// @Entry
// @Component
// struct RegisterPage {
//   @State userAccount: string = '';
//   @State password: string = '';
//   @State confirmPassword: string = '';
//   @State username: string = '';
//   @State telephoneNumber: string = '';
//   @State isLoading: boolean = false;
//
//   /**
//    * 注册
//    */
//   async register() {
//     // 表单验证
//     if (!this.userAccount.trim()) {
//       promptAction.showToast({ message: '请输入账号' });
//       return;
//     }
//     if (!this.password.trim()) {
//       promptAction.showToast({ message: '请输入密码' });
//       return;
//     }
//     if (this.password !== this.confirmPassword) {
//       promptAction.showToast({ message: '两次输入的密码不一致' });
//       return;
//     }
//     if (!this.username.trim()) {
//       promptAction.showToast({ message: '请输入用户名' });
//       return;
//     }
//     if (!this.telephoneNumber.trim()) {
//       promptAction.showToast({ message: '请输入手机号' });
//       return;
//     }
//
//     this.isLoading = true;
//     try {
//       const request: RegisterRequest = {
//         userAccount: this.userAccount.trim(),
//         password: this.password.trim(),
//         username: this.username.trim(),
//         telephoneNumber: this.telephoneNumber.trim()
//       };
//
//       const response = await ApiService.register(request);
//       if (response.code === 1) {
//         promptAction.showToast({ message: '注册成功' });
//         // 返回登录页面
//         router.back();
//       } else {
//         promptAction.showToast({ message: response.msg || '注册失败' });
//       }
//     } catch (error: Error) {
//       console.error('注册失败:', error);
//       promptAction.showToast({ message: '注册失败，请检查网络连接' });
//     } finally {
//       this.isLoading = false;
//     }
//   }
//
//   /**
//    * 返回
//    */
//   goBack() {
//     router.back();
//   }
//
//   build() {
//     Column() {
//       // 顶部导航�?
//       Row() {
//         Text('←')
//           .fontSize(24)
//           .fontColor(Color.White)
//           .onClick(() => this.goBack())
//
//         Text('注册')
//           .fontSize(18)
//           .fontWeight(FontWeight.Bold)
//           .fontColor(Color.White)
//           .margin({ left: 16 })
//
//         Blank()
//       }
//       .width('100%')
//       .height(56)
//       .padding({ left: 16, right: 16 })
//       .backgroundColor(Color.Transparent)
//
//       // 注册表单
//       Scroll() {
//         Column({ space: 20 }) {
//           // 标题区域
//           Column({ space: 8 }) {
//             Text('创建账号')
//               .fontSize(24)
//               .fontWeight(FontWeight.Bold)
//               .fontColor(Color.White)
//
//             Text('加入我们，分享你的精彩瞬间')
//               .fontSize(14)
//               .fontColor(Colors.White60)
//           }
//           .margin({ top: 20, bottom: 30 })
//
//           // 输入表单
//           Column({ space: 16 }) {
//             // 账号输入框
//             Column({ space: 8 }) {
//               Text('账号')
//                 .fontSize(14)
//                 .fontWeight(FontWeight.Medium)
//                 .fontColor(Color.White)
//                 .alignSelf(ItemAlign.Start)
//
//               TextInput({ placeholder: '请输入账号' })
//                 .width('100%')
//                 .height(48)
//                 .backgroundColor(Colors.White20)
//                 .borderRadius(8)
//                 .fontSize(16)
//                 .fontColor(Color.White)
//                 .placeholderColor(Colors.White40)
//                 .onChange((value: string) => {
//                   this.userAccount = value;
//                 })
//             }
//
//             // 用户名输入框
//             Column({ space: 8 }) {
//               Text('用户名')
//                 .fontSize(14)
//                 .fontWeight(FontWeight.Medium)
//                 .fontColor(Color.White)
//                 .alignSelf(ItemAlign.Start)
//
//               TextInput({ placeholder: '请输入用户名' })
//                 .width('100%')
//                 .height(48)
//                 .backgroundColor(Colors.White20)
//                 .borderRadius(8)
//                 .fontSize(16)
//                 .fontColor(Color.White)
//                 .placeholderColor(Colors.White40)
//                 .onChange((value: string) => {
//                   this.username = value;
//                 })
//             }
//
//             // 手机号输入框
//             Column({ space: 8 }) {
//               Text('手机号')
//                 .fontSize(14)
//                 .fontWeight(FontWeight.Medium)
//                 .fontColor(Color.White)
//                 .alignSelf(ItemAlign.Start)
//
//               TextInput({ placeholder: '请输入手机号' })
//                 .width('100%')
//                 .height(48)
//                 .backgroundColor(Colors.White20)
//                 .borderRadius(8)
//                 .fontSize(16)
//                 .fontColor(Color.White)
//                 .placeholderColor(Colors.White40)
//                 .type(InputType.PhoneNumber)
//                 .onChange((value: string) => {
//                   this.telephoneNumber = value;
//                 })
//             }
//
//             // 密码输入框
//             Column({ space: 8 }) {
//               Text('密码')
//                 .fontSize(14)
//                 .fontWeight(FontWeight.Medium)
//                 .fontColor(Color.White)
//                 .alignSelf(ItemAlign.Start)
//
//               TextInput({ placeholder: '请输入密码' })
//                 .width('100%')
//                 .height(48)
//                 .backgroundColor(Colors.White20)
//                 .borderRadius(8)
//                 .fontSize(16)
//                 .fontColor(Color.White)
//                 .placeholderColor(Colors.White40)
//                 .type(InputType.Password)
//                 .onChange((value: string) => {
//                   this.password = value;
//                 })
//             }
//
//             // 确认密码输入框
//             Column({ space: 8 }) {
//               Text('确认密码')
//                 .fontSize(14)
//                 .fontWeight(FontWeight.Medium)
//                 .fontColor(Color.White)
//                 .alignSelf(ItemAlign.Start)
//
//               TextInput({ placeholder: '请再次输入密码' })
//                 .width('100%')
//                 .height(48)
//                 .backgroundColor(Colors.White20)
//                 .borderRadius(8)
//                 .fontSize(16)
//                 .fontColor(Color.White)
//                 .placeholderColor(Colors.White40)
//                 .type(InputType.Password)
//                 .onChange((value: string) => {
//                   this.confirmPassword = value;
//                 })
//             }
//           }
//           .width('100%')
//
//           // 注册按钮
//           Button(this.isLoading ? '注册中...' : '注册')
//             .width('100%')
//             .height(48)
//             .backgroundColor('#4CAF50')
//             .borderRadius(8)
//             .fontSize(16)
//             .fontWeight(FontWeight.Medium)
//             .fontColor(Color.White)
//             .enabled(!this.isLoading)
//             .onClick(() => this.register())
//             .margin({ top: 20 })
//
//           // 登录链接
//           Row() {
//             Text('已有账号？')
//               .fontSize(14)
//               .fontColor(Colors.White60)
//
//             Text('立即登录')
//               .fontSize(14)
//               .fontColor('#4CAF50')
//               .fontWeight(FontWeight.Medium)
//               .onClick(() => this.goBack())
//           }
//           .margin({ top: 16 })
//         }
//         .width('100%')
//         .padding({ left: 32, right: 32, bottom: 32 })
//       }
//       .layoutWeight(1)
//       .scrollable(ScrollDirection.Vertical)
//       .scrollBar(BarState.Auto)
//     }
//     .width('100%')
//     .height('100%')
//     .linearGradient({
//       direction: GradientDirection.Bottom,
//       colors: [
//         ['#E8F5E8', 0.0],
//         ['#F0F8F0', 0.3],
//         ['#F8FCF8', 0.7],
//         ['#FFFFFF', 1.0]
//       ]
//     })
//   }
// }


import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { RegisterRequest } from '../models/User';
import { ApiService } from '../services/ApiService';
import { Colors } from '../common/Colors';
// import { FontWeight } from '@ohos.text';
// import { InputType } from '@ohos.input';

/** 注册页面 */
@Entry
@Component
struct RegisterPage {
  @State userAccount: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State username: string = '';
  @State telephoneNumber: string = '';
  @State isLoading: boolean = false;

  /** 注册处理 */
  async register() {
    // 表单验证
    if (!this.userAccount.trim()) {
      promptAction.showToast({ message: '请输入账号' });
      return;
    }
    if (!this.password.trim()) {
      promptAction.showToast({ message: '请输入密码' });
      return;
    }
    if (this.password !== this.confirmPassword) {
      promptAction.showToast({ message: '两次输入的密码不一致' });
      return;
    }
    if (!this.username.trim()) {
      promptAction.showToast({ message: '请输入用户名' });
      return;
    }
    if (!this.telephoneNumber.trim()) {
      promptAction.showToast({ message: '请输入邮箱' });
      return;
    }

    this.isLoading = true;
    try {
      const request: RegisterRequest = {
        userAccount: this.userAccount.trim(),
        password: this.password.trim(),
        username: this.username.trim(),
        telephoneNumber: this.telephoneNumber.trim()
      };

      const response = await ApiService.register(request);
      if (response.code === 1) {
        promptAction.showToast({ message: '注册成功' });
        // 返回登录页面
        router.back();
      } else {
        promptAction.showToast({ message: response.msg || '注册失败' });
      }
    } catch (error) {
      console.error('注册失败:', error);
      promptAction.showToast({ message: '注册失败，请检查网络连接' });
    } finally {
      this.isLoading = false;
    }
  }

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

        Text('注册')
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

      // 注册表单
      Scroll() {
        Column({ space: 20 }) {
          // 标题区域
          Column({ space: 8 }) {
            Text('创建账号')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.Black)

            Text('加入我们，分享你的精彩瞬间')
              .fontSize(14)
              .fontColor(Colors.Black60)
          }
          .margin({ top: 20, bottom: 30 })

          // 输入表单
          Column({ space: 16 }) {
            // 账号输入框
            Column({ space: 8 }) {
              Text('账号')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(Color.Black)
                .alignSelf(ItemAlign.Start)

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

            // 用户名输入框
            Column({ space: 8 }) {
              Text('用户名')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(Color.Black)
                .alignSelf(ItemAlign.Start)

              TextInput({ placeholder: '请输入用户名' })
                .width('100%')
                .height(48)
                .backgroundColor(Colors.White20)
                .borderRadius(8)
                .fontSize(16)
                .fontColor(Color.Black)
                .placeholderColor(Colors.Black40)
                .onChange((value: string) => {
                  this.username = value;
                })
            }

            // 邮箱输入框
            Column({ space: 8 }) {
              Text('邮箱')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(Color.Black)
                .alignSelf(ItemAlign.Start)

              TextInput({ placeholder: '请输入邮箱' })
                .width('100%')
                .height(48)
                .backgroundColor(Colors.White20)
                .borderRadius(8)
                .fontSize(16)
                .fontColor(Color.Black)
                .placeholderColor(Colors.Black40)
                .type(InputType.Normal)
                .onChange((value: string) => {
                  this.telephoneNumber = value;
                })
            }

            // 密码输入框
            Column({ space: 8 }) {
              Text('密码')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(Color.Black)
                .alignSelf(ItemAlign.Start)

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

            // 确认密码输入框
            Column({ space: 8 }) {
              Text('确认密码')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(Color.Black)
                .alignSelf(ItemAlign.Start)

              TextInput({ placeholder: '请再次输入密码' })
                .width('100%')
                .height(48)
                .backgroundColor(Colors.White20)
                .borderRadius(8)
                .fontSize(16)
                .fontColor(Color.Black)
                .placeholderColor(Colors.Black40)
                .type(InputType.Password)
                .onChange((value: string) => {
                  this.confirmPassword = value;
                })
            }
          }
          .width('100%')

          // 注册按钮
          Button(this.isLoading ? '注册中...' : '注册')
            .width('100%')
            .height(48)
            .backgroundColor('#4CAF50')
            .borderRadius(8)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.Black)
            .enabled(!this.isLoading)
            .onClick(() => this.register())
            .margin({ top: 20 })

          // 登录链接
          Row() {
            Text('已有账号？')
              .fontSize(14)
              .fontColor(Colors.Black60)

            Text('立即登录')
              .fontSize(14)
              .fontColor('#4CAF50')
              .fontWeight(FontWeight.Medium)
              .onClick(() => this.goBack())
          }
          .margin({ top: 16 })
        }
        .width('100%')
        .padding({ left: 32, right: 32, bottom: 32 })
      }
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Auto)
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
