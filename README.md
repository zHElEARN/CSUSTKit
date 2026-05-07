# CSUSTKit

CSUSTKit 是目前特性最全、覆盖面最广的长沙理工大学校园服务 API 库。本项目旨在为开发者提供一套统一的 Swift 接口，以轻松访问学校的各类业务系统。

无论是构建学生辅助工具、校园生活应用，还是进行相关的数据分析研究，CSUSTKit 都能提供强大的底层支持。

## 核心功能

CSUSTKit 集成了以下学校业务系统：

- 统一身份认证
  - 支持统一认证登录
  - 实现 Session 自动管理
  - 从统一身份认证登录其他系统

- 教务系统
  - 获取个人课表、学期安排等
  - 查询考试安排与考场信息等
  - 获取课程成绩与学分详情等
  - ...

- 网络教学平台
  - 查询课程列表
  - 获取课程作业、测验及其完成状态
  - 支持查询未完成的作业

- 大学物理实验平台
  - 获取物理实验课程安排
  - 查询实验成绩与报告状态

- 校园卡服务
  - 实时查询宿舍剩余电量

> [!TIP]
> 针对偶发的校园网内网访问限制问题，CSUSTKit 提供了完善的 **WebVPN** 支持：
>
> - **WebVPN访问**: 即使在非校园网环境下，也可以通过 WebVPN (`vpn.csust.edu.cn`) 代理访问仅限内网开放的系统（如教务系统）。
> - **自动处理**: 库内部自动处理 WebVPN 的 URL 加密与解密逻辑，开发者无需关心复杂的协议细节，即可实现内网服务的无缝访问。

## 安装集成

### Swift Package Manager

通过`Package.swift`添加依赖：

```swift
dependencies: [
    .package(url: "https://github.com/zHElEARN/CSUSTKit.git", from: "1.0.0")
]
```

通过Xcode添加依赖：

1. 打开你的Xcode项目
2. 选择File -> Add Packages Dependencies...
3. 在搜索框中输入 `https://github.com/zHElEARN/CSUSTKit.git`
4. 选择 `CSUSTKit` 并点击 `Add Package`

### CocoaPods

> [!WARNING]
> 本项目已不再向 CocoaPods 官方源发布新版本，强烈推荐使用 **Swift Package Manager** 进行集成。
> 
> 如果您仍需使用 CocoaPods，请通过指定 Git 仓库的方式引入。

将以下行添加到您的 `Podfile` 中：

```ruby
pod 'CSUSTKit', :git => 'https://github.com/zHElEARN/CSUSTKit.git'
```

## 使用指南

请查看示例代码：

**[Examples/CSUSTKitExample/main.swift](Examples/CSUSTKitExample/main.swift)**

该示例文件包含了从环境配置、SSO 登录、子系统访问到 WebVPN 工具使用的完整流程演示。

## 许可证

本项目采用 **MIT License**。

这意味着：

- 您可以自由地商业化使用、复制、修改和分发本项目的源代码及其副本。
- 您只需在分发时保留原作者的版权声明和许可声明即可。
- 您可以将本项目代码集成到您的闭源或商业项目中，且无需公开您自己的源代码。
- 作者不对使用本项目产生的任何后果承担法律责任。

详见 [LICENSE](LICENSE) 文件。

## 贡献

欢迎并鼓励大家为 CSUSTKit 做出贡献，您可以 Fork 项目，进行修改并提交 Pull Request。

如果您在使用过程中遇到问题，或对 CSUSTKit 有任何建议，也欢迎提交 Issue 来告知我们！

---

_免责声明: 本项目仅供学习与技术研究使用，请勿用于任何非法用途。在使用过程中请遵守学校相关网络安全规定。_
