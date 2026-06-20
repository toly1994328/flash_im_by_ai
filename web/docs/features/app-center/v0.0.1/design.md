# fx_admin — 前端设计报告

## 1. 目标

- 初始化 Vite + React 19 + TypeScript + shadcn/ui 项目
- 实现侧栏导航布局
- 应用管理页（列表 + 新增）
- 版本管理页（列表 + 新增 + 编辑 + 平台筛选）

## 2. 技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| React | 19 | UI 框架 |
| TypeScript | 5.x | 类型安全 |
| Vite | 6+ | 构建 + dev server + 代理 |
| shadcn/ui | latest | UI 组件（Table、Dialog、Form、Button、Input、Select） |
| Tailwind CSS | 4 | 样式 |
| TanStack Query | 5 | 数据请求缓存 |
| React Router | 7 | 路由 |
| React Hook Form + Zod | latest | 表单验证 |

## 3. 项目结构

```
web/fx_admin/
├── index.html
├── vite.config.ts              # Vite 配置（含 /api 代理）
├── package.json
├── tsconfig.json
├── tailwind.config.ts
├── src/
│   ├── main.tsx                # 入口
│   ├── App.tsx                 # 根组件（布局 + 路由）
│   ├── api/                    # API 请求封装
│   │   └── app-center.ts      # app/version 相关接口
│   ├── components/
│   │   └── layout/
│   │       ├── Sidebar.tsx     # 侧栏导航
│   │       └── AppLayout.tsx   # 整体布局（侧栏 + 内容区）
│   ├── pages/
│   │   ├── apps/
│   │   │   └── AppsPage.tsx    # 应用列表页
│   │   └── versions/
│   │       └── VersionsPage.tsx # 版本管理页
│   └── types/
│       └── index.ts            # TypeScript 类型定义
└── components.json             # shadcn/ui 配置
```

## 4. 页面设计

### 布局

```
┌──────────────────────────────────────────┐
│ 侧栏（200px）  │  内容区                 │
│                 │                         │
│ > 应用管理      │  页面标题               │
│   版本管理      │  ─────────────          │
│                 │                         │
│                 │  [表格/表单内容]         │
│                 │                         │
└──────────────────────────────────────────┘
```

### 应用列表页（/apps）

- 顶部：标题 + "新增应用"按钮
- 表格列：ID | 名称 | 描述 | 创建时间 | 操作（查看版本）
- 新增：点击按钮弹出 Dialog，填写 id + name + description

### 版本管理页（/apps/:appId/versions）

- 顶部：标题（含应用名）+ 平台筛选 Select + "新增版本"按钮
- 表格列：平台 | 版本号 | 下载地址 | 大小 | SHA256 | 强制更新 | 发布时间 | 操作（编辑）
- 新增/编辑：弹出 Dialog 表单

## 5. API 接口调用

| 页面 | 接口 | 方法 |
|------|------|------|
| 应用列表 | /api/app/list | GET |
| 新增应用 | /api/app | POST |
| 版本列表 | /api/app/versions?app_id=xxx | GET |
| 新增版本 | /api/app/version | POST |
| 编辑版本 | /api/app/version?app_id=xxx&platform=xxx&version=xxx | PUT |

## 6. Vite 代理配置

```ts
server: {
  proxy: {
    '/api': {
      target: 'http://127.0.0.1:9600',
      changeOrigin: true,
    }
  }
}
```

## 7. 暂不实现

| 功能 | 理由 |
|------|------|
| 登录鉴权 | 内部工具，本版本不做 |
| 删除应用/版本 | 防止误操作 |
| 文件上传 | 安装包地址手动填写 |
| 暗黑模式 | 后续优化 |
| 响应式移动端适配 | 管理后台只在桌面使用 |
