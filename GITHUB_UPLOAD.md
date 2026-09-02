# 如何上传到GitHub

## 步骤1：创建GitHub仓库

1. 登录 [GitHub](https://github.com)
2. 点击右上角 "+" -> "New repository"
3. 填写信息：
   - **Repository name**: `shield-guardian`
   - **Description**: `个人数据泄露应急助手 - 帮助用户在遭遇诈骗后快速响应和防护`
   - **Public/Private**: 选择 Public（公开）
   - ❌ 不要勾选 "Initialize this repository with a README"
4. 点击 "Create repository"

## 步骤2：安装Git（如果还没有）

### Windows安装Git：

1. 下载 Git：https://git-scm.com/download/win
2. 安装时全部使用默认选项
3. 验证安装：
```powershell
git --version
```

## 步骤3：配置Git

```powershell
# 配置用户名和邮箱（首次使用）
git config --global user.name "你的GitHub用户名"
git config --global user.email "你的GitHub邮箱"
```

## 步骤4：初始化并上传项目

```powershell
# 1. 进入项目目录
cd D:\shield-guardian

# 2. 初始化Git仓库
git init

# 3. 添加所有文件
git add .

# 4. 提交到本地仓库
git commit -m "Initial commit: Shield Guardian v1.0.0"

# 5. 添加远程仓库（替换成你的GitHub用户名）
git remote add origin https://github.com/你的用户名/shield-guardian.git

# 6. 推送到GitHub
git push -u origin master
```

**如果遇到分支名称问题：**
```powershell
# GitHub现在默认使用main分支，如果需要改名
git branch -M main
git push -u origin main
```

**如果需要登录：**
- 输入你的GitHub用户名
- 密码使用 **Personal Access Token** (不是账户密码)
- 生成Token：GitHub -> Settings -> Developer settings -> Personal access tokens -> Generate new token

## 步骤5：验证上传

1. 访问 `https://github.com/你的用户名/shield-guardian`
2. 应该能看到所有文件

## 步骤6：后续更新

```powershell
# 修改文件后
git add .
git commit -m "描述你的修改"
git push
```

## 快速命令参考

```powershell
# 查看状态
git status

# 查看修改
git diff

# 查看提交历史
git log

# 撤销修改
git checkout -- 文件名

# 拉取最新代码
git pull
```

## 常见问题

### 问题1：推送时要求身份验证

**解决方案：使用Personal Access Token**

1. GitHub -> Settings -> Developer settings -> Personal access tokens -> Tokens (classic)
2. Generate new token
3. 勾选 `repo` 权限
4. 生成并复制Token
5. 推送时用Token作为密码

### 问题2：提示"fatal: remote origin already exists"

```powershell
# 删除现有remote
git remote remove origin

# 重新添加
git remote add origin https://github.com/你的用户名/shield-guardian.git
```

### 问题3：推送被拒绝

```powershell
# 强制推送（小心使用！）
git push -f origin main
```

### 问题4：文件太大

```powershell
# 如果build文件夹被意外添加
git rm -r --cached build/
git commit -m "Remove build directory"
git push
```

## 📦 发布Release版本

上传APK到GitHub Releases：

```powershell
# 1. 编译APK
flutter build apk --release

# 2. 在GitHub上
# - 进入你的仓库
# - 点击 "Releases" -> "Create a new release"
# - Tag version: v1.0.0
# - Release title: Shield Guardian v1.0.0
# - 描述：写更新日志
# - 上传APK文件：build\app\outputs\flutter-apk\app-release.apk
# - 点击 "Publish release"
```

## 完整流程示例

```powershell
# 一次性完整上传命令
cd D:\shield-guardian
git init
git add .
git commit -m "Initial commit: Shield Guardian - Personal Data Breach Emergency Assistant"
git branch -M main
git remote add origin https://github.com/你的用户名/shield-guardian.git
git push -u origin main
```

---

**🎉 完成后，你的项目就在GitHub上了！**

分享链接格式：`https://github.com/你的用户名/shield-guardian`
