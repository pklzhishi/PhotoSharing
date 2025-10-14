import router from '@ohos.router';
import picker from '@ohos.file.picker';
import promptAction from '@ohos.promptAction';
import fs from '@ohos.file.fs';
import image from '@ohos.multimedia.image';
import { ImageUploadRequest } from '../models/Image';
import { ApiService } from '../services/ApiService';
import { Colors } from '../common/Colors';
import { ApiResponse } from '../models/User';
import { MultipartBuilder } from '../services/MultipartBuilder';
import http from '@ohos.net.http';

/**
 * 图片上传页面
 */
@Entry
@Component
struct UploadPage {
  @State selectedImagePath: string = '';
  @State imageName: string = '';
  @State content: string = '';
  @State isUploading: boolean = false;
  @State previewImage: image.PixelMap | null = null;

  /**
   * 选择图片
   */
  async selectImage() {
    try {
      const photoSelectOptions = new picker.PhotoSelectOptions();
      photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;

      const photoPicker = new picker.PhotoViewPicker();
      const photoSelectResult = await photoPicker.select(photoSelectOptions);

       if (photoSelectResult.photoUris && photoSelectResult.photoUris.length > 0) {
         this.selectedImagePath = photoSelectResult.photoUris[0];
         this.loadPreviewImage();

         // 提取文件扩展名用于生成文件名
         const pathExtension = this.selectedImagePath.split('.').pop()?.toLowerCase() || 'jpg';
         console.log('选择的图片路径:', this.selectedImagePath);
         console.log('提取的扩展名:', pathExtension);

        // 从文件路径中提取真实文件名
        const realFileName = this.selectedImagePath.split('/').pop() || '';
        console.log('从路径提取的真实文件名:', realFileName);
        
        // 如果没有设置图片名称，使用真实文件名
        if (!this.imageName) {
          this.imageName = realFileName; // 直接使用真实文件名
        } else {
          // 如果用户已经输入了图片名称，确保包含正确的扩展名
          const currentName = this.imageName.trim();
          if (!currentName.includes('.')) {
            // 用户没有输入扩展名，自动添加
            this.imageName = `${currentName}.${pathExtension}`;
          } else {
            // 用户已经输入了扩展名，检查是否正确
            const userExt = currentName.split('.').pop()?.toLowerCase() || '';
            if (userExt !== pathExtension) {
              // 扩展名不匹配，使用正确的扩展名
              const nameWithoutExt = currentName.split('.')[0];
              this.imageName = `${nameWithoutExt}.${pathExtension}`;
            }
          }
        }
         
         console.log('最终图片名称:', this.imageName);
       }
    } catch (error) { // 去掉类型标注
      console.error('选择图片失败:', error);
      promptAction.showToast({ message: '选择图片失败' });
    }
  }

  /**
   * 加载预览图片
   */
  async loadPreviewImage() {
    if (!this.selectedImagePath) return;

    try {
      const file = fs.openSync(this.selectedImagePath, fs.OpenMode.READ_ONLY);
      const imageSource = image.createImageSource(file.fd);
      this.previewImage = await imageSource.createPixelMap();
      fs.closeSync(file);
    } catch (error) { // 去掉类型标注
      console.error('加载预览图片失败:', error);
    }
  }

  /**
   * 上传图片
   */
  async uploadImage() {
    if (!this.selectedImagePath) {
      promptAction.showToast({ message: '请先选择图片' });
      return;
    }
    if (!this.imageName.trim()) {
      promptAction.showToast({ message: '请输入图片名称' });
      return;
    }

    this.isUploading = true;
    try {
      // 检查文件大小（限制为 10MB）
      // const file = fs.openSync(this.selectedImagePath, fs.OpenMode.READ_ONLY);
      // const stat = fs.statSync(file.fd);
      // const maxSize = 10 * 1024 * 1024; // 10MB
      //
      // if (stat.size > maxSize) {
      //   fs.closeSync(file);
      //   promptAction.showToast({ message: '图片文件过大，请选择小于10MB的图片' });
      //   return;
      // }
      // fs.closeSync(file);

        console.log('开始上传图片，文件名:', this.imageName.trim());
        console.log('文件路径:', this.selectedImagePath);
        console.log('内容描述:', this.content.trim());
        
        // 添加文件格式检查 - 从实际文件路径中提取扩展名
        const actualFileExtension = this.selectedImagePath.split('.').pop()?.toLowerCase() || '';
        const userFileExtension = this.imageName.trim().split('.').pop()?.toLowerCase() || '';
        
        console.log('实际文件路径:', this.selectedImagePath);
        console.log('实际文件扩展名:', actualFileExtension);
        console.log('用户输入文件名:', this.imageName.trim());
        console.log('用户输入扩展名:', userFileExtension);
        console.log('支持的文件格式: jpg, jpeg, png, gif');
        
        // 使用实际文件扩展名进行验证
        const fileExtension = actualFileExtension;
        console.log('用于验证的扩展名:', fileExtension);
        console.log('当前文件格式是否支持:', ['jpg', 'jpeg', 'png', 'gif'].includes(fileExtension));
        
        if (!['jpg', 'jpeg', 'png', 'gif'].includes(fileExtension)) {
          promptAction.showToast({ message: '请选择 jpg、jpeg、png、gif 格式的图片' });
          return;
        }
        
        // 验证文件是否存在和可读
        try {
          const testFile = fs.openSync(this.selectedImagePath, fs.OpenMode.READ_ONLY);
          const testStat = fs.statSync(testFile.fd);
          console.log('a文件验证成功:');
          console.log('a- 文件大小:', testStat.size, '字节');
          console.log('a- 文件可读性: 正常');
          fs.closeSync(testFile);
        } catch (fileError) {
          console.error('a文件验证失败:', fileError);
          promptAction.showToast({ message: '文件读取失败，请重新选择图片' });
          return;
        }

      // 这段代码已被移除，因为上传逻辑已经通过ApiService处理


      // 直接使用原始multipart方法（已验证能成功到达后端）
      let response: ApiResponse<void>;
      try {
        console.log('a=== 开始上传流程 ===');
        console.log('a使用原始multipart方法上传...');
        console.log('a上传参数检查:');
        console.log('a- 文件名:', this.imageName.trim());
        console.log('a- 文件路径:', this.selectedImagePath);
        console.log('a- 内容描述:', this.content.trim());
        
        // 提取用户输入的图片名称（不包含扩展名）
        const userImageName = this.imageName.trim().split('.')[0];
        // 从文件路径获取实际扩展名
        const actualExtension = this.selectedImagePath.split('.').pop()?.toLowerCase() || 'jpg';
        // 构建完整文件名：用户名称 + 实际扩展名
        const fullFileName = `${userImageName}.${actualExtension}`;
        
        console.log('你用户输入的图片名称（不含扩展名）:', userImageName);
        console.log('你从文件路径获取的扩展名:', actualExtension);
        console.log('你构建的完整文件名:', fullFileName);
        console.log('你实际文件路径:', this.selectedImagePath);
        console.log('你用户当前输入的文件名:', this.imageName.trim());
        console.log('你即将传递给后端的imageName字段:', userImageName);
        console.log('你即将传递给后端的multipartFile字段:', fullFileName);
        
        // 验证文件完整性
        try {
          const testFile = fs.openSync(this.selectedImagePath, fs.OpenMode.READ_ONLY);
          const testStat = fs.statSync(testFile.fd);
          const testBuffer = new ArrayBuffer(testStat.size);
          fs.readSync(testFile.fd, testBuffer);
          fs.closeSync(testFile);
          
          const testArray = new Uint8Array(testBuffer);
          console.log('a文件验证 - 原始大小:', testArray.length);
          console.log('a文件验证 - 前10个字节:', Array.from(testArray.slice(0, 10)));
          console.log('a文件验证 - 后10个字节:', Array.from(testArray.slice(-10)));
        } catch (verifyError) {
          console.error('a文件验证失败:', verifyError);
          throw new Error('文件验证失败');
        }
        
        // 尝试使用鸿蒙原生FormData方法（不使用Base64）
        response = await ApiService.uploadImageFileFormData(fullFileName, this.selectedImagePath, this.content.trim());
      } catch (error) {
        console.error('上传失败:', error);
        if (error instanceof Error) {
          throw error;
        } else {
          throw new Error(String(error));
        }
      }
      console.log('你上传响应详情:');
      console.log('你- 响应码:', response.code);
      console.log('你 响应消息:', response.msg);
      console.log('你 响应数据:', response.data);
      console.log('你- 完整响应:', JSON.stringify(response));

      if (response.code === 1) {
        console.log('a上传成功，准备清空表单');
        promptAction.showToast({ message: '上传成功' });
        // 清空表单
        this.selectedImagePath = '';
        this.imageName = '';
        this.content = '';
        this.previewImage = null;
        // 返回主页
        router.back();
      } else {
        console.error('a上传失败，响应码:', response.code, '错误信息:', response.msg);
        promptAction.showToast({ message: response.msg || '上传失败' });
      }
    } catch (error) {
      console.error('上传异常:', error);
      if (error instanceof Error) {
        promptAction.showToast({ message: `上传失败: ${error.message}` });
      } else {
        promptAction.showToast({ message: '上传失败，请检查网络连接' });
      }
    } finally {
      this.isUploading = false;
    }
  }


  /**
   * 返回
   */
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

        Text('上传图片')
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

      // 上传表单
      Column({ space: 24 }) {
        // 图片选择区域
        Column({ space: 16 }) {
          Text('选择图片')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.Black)
            .alignSelf(ItemAlign.Start)

          if (this.previewImage) {
            // 显示预览图片
            Image(this.previewImage)
              .width('100%')
              .height(200)
              .borderRadius(12)
              .objectFit(ImageFit.Cover)
              .backgroundColor(Colors.White20)
          } else {
            // 图片选择按钮
            Column() {
              Text('📷')
                .fontSize(48)
                .opacity(0.6)
            }
            .width('100%')
            .height(200)
            .borderRadius(12)
            .backgroundColor(Colors.White10)
            .border({
              width: 2,
              color: Colors.White20,
              style: BorderStyle.Dashed
            })
            .justifyContent(FlexAlign.Center)
          }

          Button(this.previewImage ? '重新选择' : '选择图片')
            .width('100%')
            .height(40)
            .backgroundColor(Colors.White20)
            .borderRadius(8)
            .fontSize(14)
            .fontColor(Color.Black)
            .onClick(() => this.selectImage())
        }
        .width('100%')

        // 图片名称输入
        Column({ space: 8 }) {
          Text('图片名称')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.Black)
            .alignSelf(ItemAlign.Start)

          TextInput({ placeholder: '请输入图片名称' })
            .width('100%')
            .height(48)
            .backgroundColor(Colors.White20)
            .borderRadius(8)
            .fontSize(16)
            .fontColor(Color.Black)
            .placeholderColor(Colors.Black40)
            .onChange((value: string) => {
              this.imageName = value;
            })
        }
        .width('100%')

        // 内容描述输入
        Column({ space: 8 }) {
          Text('内容描述')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.Black)
            .alignSelf(ItemAlign.Start)

          TextArea({ placeholder: '请输入图片内容描述（可选）' })
            .width('100%')
            .height(80)
            .backgroundColor(Colors.White20)
            .borderRadius(8)
            .fontSize(16)
            .fontColor(Color.Black)
            .placeholderColor(Colors.Black40)
            .onChange((value: string) => {
              this.content = value;
            })
        }
        .width('100%')

        // 上传按钮
        Button(this.isUploading ? '上传中...' : '上传图片')
          .width('100%')
          .height(48)
          .backgroundColor('#4CAF50')
          .borderRadius(8)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .enabled(!this.isUploading && this.selectedImagePath !== '')
          .onClick(() => this.uploadImage())
          .margin({ top: 20 })

        // 提示信息
        Text('支持 JPG、PNG 格式，建议大小不超过 10MB')
          .fontSize(12)
          .fontColor(Colors.Black60)
          .textAlign(TextAlign.Center)
          .margin({ top: 16 })
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 24 })
      .layoutWeight(1)
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
